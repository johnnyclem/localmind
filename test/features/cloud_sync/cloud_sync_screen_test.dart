import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/providers/storage_providers.dart';
import 'package:localmind/features/cloud_sync/views/cloud_sync_screen.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpCloudSyncScreen(
    WidgetTester tester, {
    Size size = const Size(800, 600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CloudSyncScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows setup fields and encryption controls when disabled', (
    tester,
  ) async {
    await pumpCloudSyncScreen(tester);

    expect(find.text('S3 Cloud Sync'), findsOneWidget);
    expect(find.text('Endpoint URL'), findsOneWidget);
    expect(find.text('Bucket'), findsOneWidget);
    expect(find.text('Encryption passphrase'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Test connection'), findsOneWidget);
    expect(find.text('Enable encrypted sync'), findsOneWidget);
  });

  testWidgets('keeps setup fields separated on a compact viewport', (
    tester,
  ) async {
    await pumpCloudSyncScreen(tester, size: const Size(320, 568));

    final endpoint = find.widgetWithText(TextFormField, 'Endpoint URL');
    final bucket = find.widgetWithText(TextFormField, 'Bucket');

    expect(endpoint, findsOneWidget);
    expect(bucket, findsOneWidget);
    expect(
      tester.getBottomLeft(endpoint).dy,
      lessThan(tester.getTopLeft(bucket).dy),
    );
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Enable encrypted sync'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
