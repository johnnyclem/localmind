import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tools/tool_registry.dart';
import '../data/tools/builtin_tool_provider.dart';
import '../data/tools/mcp_tool_provider.dart';
import '../data/mcp_server_manager.dart';

final mcpServerManagerProvider = Provider<McpServerManager>((ref) {
  return McpServerManager();
});

final builtInToolProviderProvider = Provider<BuiltInToolProvider>((ref) {
  return BuiltInToolProvider();
});

final toolRegistryProvider = Provider<ToolRegistry>((ref) {
  final mcpServerManager = ref.watch(mcpServerManagerProvider);
  return ToolRegistry(
    providers: [
      ref.watch(builtInToolProviderProvider),
      if (mcpServerManager.serverCount > 0)
        McpToolProvider(serverManager: mcpServerManager),
    ],
  );
});
