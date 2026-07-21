import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../data/models/share.dart';
import '../providers/connections_providers.dart';

/// Invite/share bottom sheet (mobile PRD M5, T-M5-03/04/07): invite a
/// HyperVault user to an artifact by email (`POST /api/shares`), and list +
/// revoke current grantees (`GET`/`DELETE /api/shares`).
Future<void> showShareSheet(
  BuildContext context, {
  required String artifactSlug,
  required String artifactTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _ShareSheet(artifactSlug: artifactSlug, artifactTitle: artifactTitle),
  );
}

class _ShareSheet extends ConsumerStatefulWidget {
  final String artifactSlug;
  final String artifactTitle;

  const _ShareSheet({required this.artifactSlug, required this.artifactTitle});

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final _emailController = TextEditingController();

  bool _loadingShares = true;
  String? _sharesError;
  List<ArtifactShare> _shares = const [];

  bool _submitting = false;
  String? _submitError;

  final Set<String> _revokingIds = {};

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadShares() async {
    setState(() {
      _loadingShares = true;
      _sharesError = null;
    });
    try {
      final shares = await ref
          .read(sharesApiServiceProvider)
          .fetchShares(widget.artifactSlug);
      if (mounted) {
        setState(() {
          _shares = shares;
          _loadingShares = false;
        });
      }
    } on HyperVaultApiException catch (e) {
      if (mounted) {
        setState(() {
          _sharesError = e.message;
          _loadingShares = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sharesError = 'Could not load current access.';
          _loadingShares = false;
        });
      }
    }
  }

  Future<void> _share() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _submitError = 'Enter an email address.');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final result = await ref
          .read(sharesApiServiceProvider)
          .share(artifact: widget.artifactSlug, email: email);
      _emailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
      await _loadShares();
    } on HyperVaultApiException catch (e) {
      if (mounted) setState(() => _submitError = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _submitError =
              'Could not share — check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _revoke(ArtifactShare share) async {
    setState(() => _revokingIds.add(share.id));
    final previous = _shares;
    try {
      final message = await ref.read(sharesApiServiceProvider).revoke(share.id);
      if (mounted) {
        setState(() {
          _shares = _shares.where((s) => s.id != share.id).toList();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } on HyperVaultApiException catch (e) {
      if (mounted) {
        setState(() => _shares = previous);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _shares = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not revoke access.')),
        );
      }
    } finally {
      if (mounted) setState(() => _revokingIds.remove(share.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedShare08, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Share "${widget.artifactTitle}"',
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _emailController,
                    placeholder: const Text('Email address'),
                    keyboardType: TextInputType.emailAddress,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedMail01,
                        size: 16,
                      ),
                    ),
                    onSubmitted: (_) => _submitting ? null : _share(),
                  ),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: _submitting ? null : _share,
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    size: 16,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Share'),
                ),
              ],
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 8),
              Text(
                _submitError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            Text('Has access', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_loadingShares)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_sharesError != null)
              Text(_sharesError!, style: theme.textTheme.bodySmall)
            else if (_shares.isEmpty)
              Text(
                'Not shared with anyone yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            else
              ..._shares.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.label),
                  subtitle: (s.displayName != null && s.email != null)
                      ? Text(s.email!)
                      : null,
                  trailing: _revokingIds.contains(s.id)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedRemove01,
                            size: 18,
                          ),
                          tooltip: 'Revoke access',
                          onPressed: () => _revoke(s),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
