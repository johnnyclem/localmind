import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/device/device_memory_service.dart';
import 'package:localmind/core/providers/device_info_providers.dart';
import 'package:localmind/core/providers/storage_providers.dart';
import 'package:localmind/core/theme/app_theme.dart';
import 'package:localmind/features/on_device/data/imported_gguf_model_repository.dart';
import 'package:localmind/features/on_device/data/on_device_gemma_service.dart';
import 'package:localmind/features/on_device/providers/on_device_providers.dart';
import 'package:localmind/features/on_device/views/model_manager_screen.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  const storageKey = 'imported_gguf_models_v1';

  testWidgets('model manager shows Import GGUF and imported model actions', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final metadata = ImportedGgufModelMetadata(
        id: 'gguf-widget',
        name: 'Widget GGUF',
        filePath: '/tmp/widget.gguf',
        fileSizeBytes: 4096,
        importedAt: DateTime.utc(2026, 6, 21),
      );
      SharedPreferences.setMockInitialValues({
        storageKey: json.encode([metadata.toJson()]),
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            onDeviceGemmaServiceProvider.overrideWithValue(
              _FakeOnDeviceGemmaService(),
            ),
            deviceMemoryProvider.overrideWith(
              (ref) async => const DeviceMemoryInfo(
                totalMemoryMb: 8192,
                availableMemoryMb: 8192,
              ),
            ),
          ],
          child: ShadTheme(
            data: AppTheme.lightShadTheme,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: OnDeviceModelManagerScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Import GGUF'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Widget GGUF'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(find.text('Widget GGUF'), findsOneWidget);
      expect(find.text('Imported'), findsWidgets);
      expect(find.text('GGUF'), findsWidgets);
      expect(find.text('llama.cpp'), findsWidgets);
      expect(find.text('Load'), findsWidgets);
      expect(find.text('Delete'), findsWidgets);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _FakeOnDeviceGemmaService extends OnDeviceGemmaService {
  @override
  Future<List<String>> getInstalledModelIds() async {
    return [];
  }
}
