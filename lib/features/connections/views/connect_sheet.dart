import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/artifact_identity_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../vault/data/models/artifact.dart';
import '../../vault/providers/vault_providers.dart';
import '../data/models/connection.dart';
import '../providers/connections_providers.dart';

/// Connect bottom sheet (mobile PRD M5, T-M5-01/02/07): search the user's
/// other artifacts and tap one to `POST /api/connections`, with existing
/// connections listed below (each removable via `DELETE /api/connections`).
///
/// v1 scope is artifact-to-artifact connect only (per the epic brief, memory
/// targets depend on M4/M6 and are skipped here to keep this reliable).
Future<void> showConnectSheet(
  BuildContext context, {
  required String artifactSlug,
  required String artifactTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ConnectSheet(
      artifactSlug: artifactSlug,
      artifactTitle: artifactTitle,
    ),
  );
}

class _ConnectSheet extends ConsumerStatefulWidget {
  final String artifactSlug;
  final String artifactTitle;

  const _ConnectSheet({required this.artifactSlug, required this.artifactTitle});

  @override
  ConsumerState<_ConnectSheet> createState() => _ConnectSheetState();
}

class _ConnectSheetState extends ConsumerState<_ConnectSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  // Existing-connections state. Hydrating the raw connections id-only
  // response into slugs/titles needs this artifact's own internal id, which
  // no REST endpoint exposes (GET /api/artifacts never returns `id`) — so
  // this is resolved through the shared [ArtifactIdentityCache] (the same
  // identity map `_connect` below writes to), not a bespoke direct-Supabase
  // read. A connection whose other end this device has never learned an id
  // for (e.g. made purely from the web app) can't be resolved yet and is
  // simply omitted — see that cache's doc comment for the accepted
  // limitation.
  bool _loadingConnections = true;
  String? _connectionsError;
  List<ArtifactConnectionRow> _connections = const [];

  final Set<String> _connectingSlugs = {};
  String? _connectError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
    _loadExistingConnections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingConnections() async {
    setState(() {
      _loadingConnections = true;
      _connectionsError = null;
    });
    try {
      final cache = ref.read(artifactIdentityCacheProvider);
      final userId = ref.read(authProvider).user?.id;
      final ownId = cache.idForSlug(userId, widget.artifactSlug);
      if (ownId == null) {
        // This device has never learned this artifact's database id (no
        // mobile-made connection has touched it yet) — nothing to resolve.
        if (mounted) {
          setState(() {
            _connections = const [];
            _loadingConnections = false;
          });
        }
        return;
      }

      final response = await ref
          .read(connectionsApiServiceProvider)
          .fetchConnections();
      final mine = response.connections
          .where((c) => c.involves(ownId))
          .toList();

      final vaultList = ref.read(vaultListProvider).value ?? const <Artifact>[];
      final artifactBySlug = {for (final a in vaultList) a.slug: a};

      final display = <ArtifactConnectionRow>[];
      for (final c in mine) {
        final otherId = c.otherId(ownId);
        final otherSlug = cache.slugForId(userId, otherId);
        if (otherSlug == null) {
          // Can't resolve this edge's other end yet — likely a web-made
          // connection this device hasn't touched. Omit rather than show a
          // dead entry with no title.
          continue;
        }
        final other = artifactBySlug[otherSlug];
        display.add(
          ArtifactConnectionRow(
            connectionId: c.id,
            otherArtifactId: otherId,
            otherSlug: otherSlug,
            otherTitle: other?.title ?? otherSlug,
            otherType: other?.type,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _connections = display;
          _loadingConnections = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _connectionsError = "Couldn't load existing connections right now.";
          _loadingConnections = false;
        });
      }
    }
  }

  List<Artifact> _searchResults(List<Artifact> all) {
    final connectedSlugs = _connections
        .map((c) => c.otherSlug)
        .whereType<String>()
        .toSet();
    final q = _query.trim().toLowerCase();
    return all.where((a) {
      if (a.slug == widget.artifactSlug) return false;
      if (connectedSlugs.contains(a.slug)) return false;
      if (q.isEmpty) return false; // don't dump the whole vault by default
      return a.title.toLowerCase().contains(q) ||
          a.slug.toLowerCase().contains(q) ||
          a.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _connect(Artifact target) async {
    setState(() {
      _connectingSlugs.add(target.slug);
      _connectError = null;
    });
    try {
      await ref
          .read(connectionsControllerProvider)
          .connect(source: widget.artifactSlug, target: target.slug);
      _searchController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to "${target.title}"')),
        );
      }
      await _loadExistingConnections();
    } on HyperVaultApiException catch (e) {
      if (mounted) setState(() => _connectError = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _connectError =
              'Could not connect — check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _connectingSlugs.remove(target.slug));
      }
    }
  }

  Future<void> _remove(ArtifactConnectionRow row) async {
    final previous = _connections;
    setState(() {
      _connections = _connections
          .where((c) => c.connectionId != row.connectionId)
          .toList();
    });
    try {
      await ref
          .read(connectionsApiServiceProvider)
          .disconnect(row.connectionId);
    } on HyperVaultApiException catch (e) {
      if (mounted) {
        setState(() => _connections = previous);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _connections = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove that connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultAsync = ref.watch(vaultListProvider);
    final results = vaultAsync.value == null
        ? const <Artifact>[]
        : _searchResults(vaultAsync.value!);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedConnect, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connect "${widget.artifactTitle}"',
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ShadInput(
                controller: _searchController,
                placeholder: const Text('Search your artifacts'),
                leading: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 16),
                ),
              ),
              if (_connectError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _connectError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_query.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        if (results.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No matching artifacts.',
                              style: theme.textTheme.bodySmall,
                            ),
                          )
                        else
                          ...results.map(
                            (a) => _SearchResultTile(
                              artifact: a,
                              busy: _connectingSlugs.contains(a.slug),
                              onTap: () => _connect(a),
                            ),
                          ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Current connections',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (_loadingConnections)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_connectionsError != null)
                        Text(
                          _connectionsError!,
                          style: theme.textTheme.bodySmall,
                        )
                      else if (_connections.isEmpty)
                        Text(
                          'No connections yet — search above to link a related artifact.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        )
                      else
                        ..._connections.map(
                          (c) => _ConnectionTile(
                            row: c,
                            onRemove: () => _remove(c),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Artifact artifact;
  final bool busy;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.artifact,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const HugeIcon(icon: HugeIcons.strokeRoundedConnect, size: 18),
      title: Text(artifact.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(artifact.type),
      trailing: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18),
      onTap: busy ? null : onTap,
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final ArtifactConnectionRow row;
  final VoidCallback onRemove;

  const _ConnectionTile({required this.row, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(row.otherTitle, overflow: TextOverflow.ellipsis),
      subtitle: row.otherType == null ? null : Text(row.otherType!),
      trailing: IconButton(
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18),
        tooltip: 'Remove connection',
        onPressed: onRemove,
      ),
    );
  }
}
