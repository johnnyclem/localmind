import "package:localmind/core/theme/colors.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MCP Tools',
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
                  _ExampleServerPanel(
                    enabled: hasExampleServer,
                    onToggle: _toggleExampleServer,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Available tools',
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
                          icon: Icons.error_outline,
                          title: 'Unable to load tools',
                          body: snapshot.error.toString(),
                        );
                      }

                      final tools = snapshot.data ?? const <ToolDefinition>[];
                      if (tools.isEmpty) {
                        return const _StatusPanel(
                          icon: Icons.extension_outlined,
                          title: 'No tools registered',
                          body:
                              'Enable the example MCP server or add MCP integrations from chat settings.',
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

class _ExampleServerPanel extends StatelessWidget {
  const _ExampleServerPanel({required this.enabled, required this.onToggle});

  final bool enabled;
  final VoidCallback onToggle;

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
                      'Example MCP server',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registers example.echo and example.word_count through the same MCP tool provider used by external servers.',
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
            leading: Icon(enabled ? Icons.power_settings_new : Icons.add),
            child: Text(
              enabled ? 'Disable example server' : 'Enable example server',
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
          Icon(
            isMcp ? Icons.hub_outlined : Icons.functions,
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
                      label: isMcp ? 'MCP' : 'Built-in',
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

  final IconData icon;
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
          Icon(icon, size: 32, color: theme.colorScheme.outline),
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
