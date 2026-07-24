import "package:localmind/core/theme/colors.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/routes/app_routes.dart';
import '../../chat/data/mcp_server_manager.dart';
import '../../chat/data/tools/tool_definition.dart';
import '../../chat/providers/tooling_providers.dart';

class McpToolsScreen extends ConsumerStatefulWidget {
  const McpToolsScreen({super.key});

  @override
  ConsumerState<McpToolsScreen> createState() => _McpToolsScreenState();
}

class _McpToolsScreenState extends ConsumerState<McpToolsScreen> {
  Future<List<ToolDefinition>>? _toolsFuture;

  @override
  void initState() {
    super.initState();
    _toolsFuture = _loadTools();
  }

  Future<List<ToolDefinition>> _loadTools() {
    return ref.read(toolRegistryProvider).listTools();
  }

  void _refreshTools() {
    ref.invalidate(toolRegistryProvider);
    setState(() {
      _toolsFuture = _loadTools();
    });
  }

  void _toggleExampleServer() {
    final manager = ref.read(mcpServerManagerProvider);
    if (manager.hasExampleServer()) {
      manager.removeServer(exampleMcpServerLabel);
    } else {
      manager.addExampleServer();
    }
    _refreshTools();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final manager = ref.watch(mcpServerManagerProvider);
    final hasExampleServer = manager.hasExampleServer();
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: topPadding + 8,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE5E5E5),
              ),
            ),
          ),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedMenu01),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.mcp_tools_title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refreshTools(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _BrowseRegistryBanner(
                  onTap: () => context.push(AppRoutes.mcpRegistry),
                ),
                const SizedBox(height: 12),
                _ExampleServerPanel(
                  enabled: hasExampleServer,
                  onToggle: _toggleExampleServer,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.available_tools,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ToolDefinition>>(
                  future: _toolsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _StatusPanel(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        title: l10n.unable_load_tools,
                        body: snapshot.error.toString(),
                      );
                    }

                    final tools = snapshot.data ?? const <ToolDefinition>[];
                    if (tools.isEmpty) {
                      return _StatusPanel(
                        icon: HugeIcons.strokeRoundedPuzzle,
                        title: l10n.no_tools_registered,
                        body: l10n.no_tools_registered_desc,
                      );
                    }

                    return Column(
                      children: tools
                          .map((tool) => _ToolRow(tool: tool))
                          .toList(growable: false),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BrowseRegistryBanner extends StatelessWidget {
  const _BrowseRegistryBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedDownload01,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GitHub MCP Registry',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Browse and one-click install MCP servers.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ShadButton.outline(onPressed: onTap, child: const Text('Browse')),
        ],
      ),
    );
  }
}

class _ExampleServerPanel extends StatelessWidget {
  const _ExampleServerPanel({required this.enabled, required this.onToggle});

  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMcpServer,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.example_mcp_server_title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.example_mcp_server_desc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShadButton(
            onPressed: onToggle,
            leading: HugeIcon(icon: enabled ? HugeIcons.strokeRoundedPower : HugeIcons.strokeRoundedAdd01),
            child: Text(
              enabled
                  ? l10n.disable_example_server
                  : l10n.enable_example_server,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.tool});

  final ToolDefinition tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isMcp = tool.providerType == ToolProviderType.mcp;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: 
            isMcp ? HugeIcons.strokeRoundedShare01 : HugeIcons.strokeRoundedCalculate,
            size: 20,
            color: isMcp
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (tool.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tool.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ToolBadge(
                      label: isMcp ? 'MCP' : l10n.built_in_label,
                      color: isMcp
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    if (tool.providerRef != null)
                      _ToolBadge(
                        label: tool.providerRef!,
                        color: theme.colorScheme.secondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBadge extends StatelessWidget {
  const _ToolBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, size: 32, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
