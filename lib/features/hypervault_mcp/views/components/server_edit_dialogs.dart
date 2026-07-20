import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../data/models/hv_mcp_server.dart';
import '../../providers/hypervault_mcp_providers.dart';

/// Rename dialog — direct `PATCH /api/mcp-servers/[id]` edit (not draft).
Future<void> showRenameServerDialog(BuildContext context, WidgetRef ref, HvMcpServer server) async {
  final controller = TextEditingController(text: server.name);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename server'),
      content: ShadInput(controller: controller, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (name == null || name.isEmpty || name == server.name || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(hvMcpConsoleProvider.notifier).renameServer(server.id, name);
  } on HvApiError catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.error)));
  }
}

/// Auth headers dialog — set a fresh header set or clear the stored one.
/// The API never returns header values, so this only ever writes.
Future<void> showEditHeadersDialog(BuildContext context, WidgetRef ref, HvMcpServer server) async {
  final keyController = TextEditingController();
  final valueController = TextEditingController();
  final action = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit auth headers'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            server.hasAuth
                ? 'A header is currently stored — it is write-only and cannot be '
                      'shown. Enter a new one to replace it, or clear it below.'
                : 'No auth header stored for this server.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ShadInput(controller: keyController, placeholder: const Text('Header')),
          const SizedBox(height: 8),
          ShadInput(controller: valueController, placeholder: const Text('Value'), obscureText: true),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (server.hasAuth)
          TextButton(
            onPressed: () => Navigator.pop(context, 'clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        TextButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save')),
      ],
    ),
  );
  final key = keyController.text.trim();
  final value = valueController.text.trim();
  keyController.dispose();
  valueController.dispose();
  if (action == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    if (action == 'clear') {
      await ref.read(hvMcpConsoleProvider.notifier).updateServerHeaders(server.id, clear: true);
    } else if (key.isNotEmpty && value.isNotEmpty) {
      await ref
          .read(hvMcpConsoleProvider.notifier)
          .updateServerHeaders(server.id, headers: {key: value});
    }
  } on HvApiError catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.error)));
  }
}
