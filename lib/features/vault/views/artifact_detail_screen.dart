import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../connections/views/connect_sheet.dart';
import '../../connections/views/share_sheet.dart';
import '../data/models/artifact.dart';
import '../providers/vault_providers.dart';

/// Artifact detail/viewer (mobile PRD T-M3-02 through T-M3-12, scoped to
/// v1). Deep-linkable by [slug] alone — if the artifact isn't already in
/// [vaultListProvider]'s cached list, this fetches the list once to find it.
class ArtifactDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const ArtifactDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ArtifactDetailScreen> createState() =>
      _ArtifactDetailScreenState();
}

class _ArtifactDetailScreenState extends ConsumerState<ArtifactDetailScreen> {
  Artifact? _artifact;
  bool _loadingArtifact = true;
  bool _isFallback = false;
  String? _loadError;

  String? _feedback;
  bool _feedbackBusy = false;

  bool _visibilityBusy = false;
  bool _deleting = false;

  WebViewController? _webViewController;
  bool _webViewLoading = true;
  String? _webViewError;

  @override
  void initState() {
    super.initState();
    _loadArtifact();
    _loadFeedback();
  }

  Future<void> _loadArtifact() async {
    final notifier = ref.read(vaultListProvider.notifier);
    var found = notifier.findBySlug(widget.slug);
    if (found == null) {
      try {
        await ref.read(vaultListProvider.notifier).refresh();
      } catch (_) {
        // Fall through to the not-found handling below.
      }
      found = notifier.findBySlug(widget.slug);
    }

    if (!mounted) return;

    if (found != null) {
      setState(() {
        _artifact = found;
        _loadingArtifact = false;
      });
      _initWebView(found.url);
      return;
    }

    // No dedicated single-artifact GET exists (per the API contract) — show
    // what we can from the slug alone, best-effort reconstructing the URL
    // from capabilities so the preview/source/feedback still work.
    final appUrl = ref.read(capabilitiesProvider).value?.appUrl ?? '';
    final fallbackUrl = appUrl.isEmpty ? '' : '$appUrl/a/${widget.slug}';
    setState(() {
      _artifact = Artifact(
        slug: widget.slug,
        title: widget.slug,
        type: 'unknown',
        tags: const [],
        isPwa: false,
        isJsx: false,
        visibility: 'private',
        createdAt: DateTime.now(),
        url: fallbackUrl,
      );
      _isFallback = true;
      _loadingArtifact = false;
      if (fallbackUrl.isEmpty) {
        _loadError = 'Could not find this artifact in your vault list.';
      }
    });
    if (fallbackUrl.isNotEmpty) _initWebView(fallbackUrl);
  }

  void _initWebView(String url) {
    if (url.isEmpty) return;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _webViewLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _webViewLoading = false);
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _webViewLoading = false;
                _webViewError = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
    setState(() {
      _webViewController = controller;
    });
  }

  Future<void> _loadFeedback() async {
    try {
      final feedback = await ref
          .read(vaultApiServiceProvider)
          .fetchFeedback(widget.slug);
      if (mounted) setState(() => _feedback = feedback);
    } catch (_) {
      // Feedback is a nice-to-have; silently leave it unset on failure.
    }
  }

  void _showError(Object e) {
    final message = e is HyperVaultApiException ? e.message : e.toString();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleFeedback(String value) async {
    final next = _feedback == value ? null : value;
    final previous = _feedback;
    setState(() {
      _feedback = next;
      _feedbackBusy = true;
    });
    try {
      final confirmed = await ref
          .read(vaultApiServiceProvider)
          .postFeedback(widget.slug, next);
      if (mounted) setState(() => _feedback = confirmed);
    } catch (e) {
      if (mounted) setState(() => _feedback = previous);
      _showError(e);
    } finally {
      if (mounted) setState(() => _feedbackBusy = false);
    }
  }

  Future<void> _toggleVisibility(bool makePublic) async {
    final newVisibility = makePublic ? 'public' : 'private';
    final previous = _artifact;
    setState(() {
      _artifact = _artifact?.copyWith(visibility: newVisibility);
      _visibilityBusy = true;
    });
    try {
      await ref
          .read(vaultListProvider.notifier)
          .setVisibility(widget.slug, newVisibility);
    } catch (e) {
      if (mounted) setState(() => _artifact = previous);
      _showError(e);
    } finally {
      if (mounted) setState(() => _visibilityBusy = false);
    }
  }

  void _copyLink() {
    final url = _artifact?.url;
    if (url == null || url.isEmpty) {
      _showError(const HyperVaultApiException(message: 'No link to copy.'));
      return;
    }
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete artifact?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(vaultListProvider.notifier).deleteArtifact(widget.slug);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _deleting = false);
      _showError(e);
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SourceSheet(slug: widget.slug),
    );
  }

  void _showConnectSheet() {
    final artifact = _artifact;
    if (artifact == null) return;
    showConnectSheet(
      context,
      artifactSlug: artifact.slug,
      artifactTitle: artifact.title,
    );
  }

  void _showShareSheet() {
    final artifact = _artifact;
    if (artifact == null) return;
    showShareSheet(
      context,
      artifactSlug: artifact.slug,
      artifactTitle: artifact.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artifact = _artifact;

    return Scaffold(
      appBar: AppBar(
        title: Text(artifact?.title ?? 'Artifact'),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedConnect),
            tooltip: 'Connect',
            onPressed: artifact == null ? null : _showConnectSheet,
          ),
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedShare08),
            tooltip: 'Share',
            onPressed: artifact == null ? null : _showShareSheet,
          ),
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedCopy01),
            tooltip: 'Copy link',
            onPressed: artifact == null ? null : _copyLink,
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              color: Colors.red,
            ),
            tooltip: 'Delete',
            onPressed: _deleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: _loadingArtifact
          ? const Center(child: CircularProgressIndicator())
          : artifact == null
          ? Center(
              child: Text(
                _loadError ?? 'Artifact not found.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isFallback)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'This artifact was opened directly and isn\'t in your '
                      'cached vault list yet — some details may be missing.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    GestureDetector(
                      onTap: _showSourceSheet,
                      child: ShadBadge.secondary(child: Text(artifact.type)),
                    ),
                    if (artifact.isJsx)
                      const ShadBadge(child: Text('React · auto-wrapped')),
                    if (artifact.isPwa)
                      ShadBadge.outline(child: const Text('Installable')),
                    ...artifact.tags.map(
                      (tag) => Text(
                        '#$tag',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (artifact.sourcePrompt != null &&
                    artifact.sourcePrompt!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Source prompt'),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(artifact.sourcePrompt!),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ShadSwitch(
                        value: artifact.isPublic,
                        enabled: !_visibilityBusy,
                        onChanged: _toggleVisibility,
                        label: Text(
                          artifact.isPublic ? 'Public' : 'Private',
                        ),
                        sublabel: Text(
                          artifact.isPublic
                              ? 'Anyone with the link can view this.'
                              : 'Only you can view this.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedThumbsUp,
                        color: _feedback == 'up'
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      onPressed: _feedbackBusy
                          ? null
                          : () => _toggleFeedback('up'),
                    ),
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedThumbsDown,
                        color: _feedback == 'down'
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      onPressed: _feedbackBusy
                          ? null
                          : () => _toggleFeedback('down'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showSourceSheet,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedSourceCode,
                      ),
                      label: const Text('View source'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPreview(artifact),
              ],
            ),
    );
  }

  Widget _buildPreview(Artifact artifact) {
    if (artifact.url.isEmpty) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 480,
        child: Stack(
          children: [
            if (_webViewController != null)
              WebViewWidget(controller: _webViewController!)
            else
              const SizedBox.shrink(),
            if (_webViewLoading)
              const Center(child: CircularProgressIndicator()),
            if (_webViewError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load preview: $_webViewError',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceSheet extends ConsumerStatefulWidget {
  final String slug;

  const _SourceSheet({required this.slug});

  @override
  ConsumerState<_SourceSheet> createState() => _SourceSheetState();
}

class _SourceSheetState extends ConsumerState<_SourceSheet> {
  String? _content;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final content = await ref
          .read(vaultApiServiceProvider)
          .fetchSource(widget.slug);
      if (mounted) setState(() => _content = content);
    } catch (e) {
      final message = e is HyperVaultApiException ? e.message : e.toString();
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Source',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_content != null)
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCopy01,
                      ),
                      tooltip: 'Copy source',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _content!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied!')),
                        );
                      },
                    ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : SingleChildScrollView(
                        controller: scrollController,
                        child: SelectableText(
                          _content ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
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
