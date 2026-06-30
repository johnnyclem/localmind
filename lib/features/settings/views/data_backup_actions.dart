import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:localmind/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/storage_providers.dart';
import '../../../core/services/data_backup_service.dart';
import '../../conversations/providers/conversation_providers.dart';
import '../../personas/providers/personas_providers.dart';

class DataBackupActions extends ConsumerWidget {
  const DataBackupActions({super.key});

  Future<void> _saveJsonExport(
    BuildContext context,
    String dialogTitle,
    String fileName,
    String json,
  ) async {
    final saved = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: Uint8List.fromList(utf8.encode(json)),
    );
    if (saved == null) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.export_data_success)),
      );
    }
  }

  Future<void> _saveZipExport(
    BuildContext context,
    WidgetRef ref,
    String dialogTitle,
    String fileName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final db = ref.read(databaseProvider);
      final settings = ref.read(settingsProvider);
      final service = DataBackupService();
      final bytes = service.exportAllZip(db.store, settings.toJson());
      final saved = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: Uint8List.fromList(bytes),
      );
      if (saved == null) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.export_data_success)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.import_data_failed(e.toString()))),
        );
      }
    }
  }

  Future<bool> _confirmImport(BuildContext context, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.import_all_data),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogL10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogL10n.confirm),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _importJsonFile(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(String json) importer,
    String confirmMessage,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirmImport(context, confirmMessage)) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      final path = result?.files.single.path;
      if (path == null) return;

      final json = await File(path).readAsString();
      await importer(json);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.import_data_success)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.import_data_failed(e.toString()))),
        );
      }
    }
  }

  Future<void> _importZipFile(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirmImport(context, l10n.import_data_confirm)) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      final path = result?.files.single.path;
      if (path == null) return;

      final bytes = await File(path).readAsBytes();
      final db = ref.read(databaseProvider);
      await DataBackupService().importZip(db.store, bytes);

      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive.files) {
        if (!file.isFile || file.name != 'settings.json') continue;
        final settingsJson = utf8.decode(file.content as List<int>);
        final decoded = jsonDecode(settingsJson) as Map<String, dynamic>;
        final settingsMap = decoded['settings'];
        if (settingsMap is Map) {
          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.setString('appSettings', jsonEncode(settingsMap));
        }
      }

      ref.invalidate(conversationsProvider);
      ref.invalidate(personasNotifierProvider);
      ref.invalidate(settingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.import_data_success)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.import_data_failed(e.toString()))),
        );
      }
    }
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadButton.outline(
        onPressed: onPressed,
        width: double.infinity,
        leading: Icon(icon, size: 16),
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final service = DataBackupService();
    final db = ref.read(databaseProvider);

    return Column(
      children: [
        _actionButton(
          icon: Icons.forum_outlined,
          label: l10n.export_conversations,
          onPressed: () => _saveJsonExport(
            context,
            l10n.export_conversations,
            'localmind_conversations_${DateTime.now().millisecondsSinceEpoch}.json',
            service.exportConversationsAsJson(db.store),
          ),
        ),
        _actionButton(
          icon: Icons.download_outlined,
          label: l10n.import_conversations,
          onPressed: () => _importJsonFile(
            context,
            ref,
            (json) => service.importFromJson(db.store, json),
            l10n.import_data_confirm,
          ),
        ),
        _actionButton(
          icon: Icons.smart_toy_outlined,
          label: l10n.export_personas,
          onPressed: () => _saveJsonExport(
            context,
            l10n.export_personas,
            'localmind_personas_${DateTime.now().millisecondsSinceEpoch}.json',
            service.exportPersonasAsJson(db.store),
          ),
        ),
        _actionButton(
          icon: Icons.download_outlined,
          label: l10n.import_personas,
          onPressed: () => _importJsonFile(
            context,
            ref,
            (json) async {
              await service.importFromJson(db.store, json);
              ref.invalidate(personasNotifierProvider);
            },
            l10n.import_data_confirm,
          ),
        ),
        _actionButton(
          icon: Icons.settings_outlined,
          label: l10n.export_settings,
          onPressed: () => _saveJsonExport(
            context,
            l10n.export_settings,
            'localmind_settings_${DateTime.now().millisecondsSinceEpoch}.json',
            service.exportSettingsAsJson(ref.read(settingsProvider).toJson()),
          ),
        ),
        _actionButton(
          icon: Icons.download_outlined,
          label: l10n.import_settings,
          onPressed: () => _importJsonFile(
            context,
            ref,
            (json) async {
              final decoded = jsonDecode(json) as Map<String, dynamic>;
              final settingsMap = decoded['settings'] ?? decoded;
              final prefs = ref.read(sharedPreferencesProvider);
              await prefs.setString('appSettings', jsonEncode(settingsMap));
              ref.invalidate(settingsProvider);
            },
            l10n.import_settings_confirm,
          ),
        ),
        _actionButton(
          icon: Icons.folder_zip_outlined,
          label: l10n.export_all_zip,
          onPressed: () => _saveZipExport(
            context,
            ref,
            l10n.export_all_zip,
            'localmind_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
          ),
        ),
        _actionButton(
          icon: Icons.unarchive_outlined,
          label: l10n.import_all_zip,
          onPressed: () => _importZipFile(context, ref),
        ),
      ],
    );
  }
}
