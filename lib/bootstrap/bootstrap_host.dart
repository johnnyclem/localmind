import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../core/providers/highlighter_provider.dart';
import '../core/providers/storage_providers.dart';
import '../core/storage/objectbox_store.dart';
import '../features/on_device/providers/on_device_providers.dart';
import '../core/models/enums.dart';
import '../features/servers/data/models/server.dart';
import '../features/servers/providers/server_providers.dart';
import 'bootstrap_screen.dart';
import 'bootstrap_state.dart';

class BootstrapHost extends StatefulWidget {
  const BootstrapHost({super.key});

  @override
  State<BootstrapHost> createState() => _BootstrapHostState();
}

class _BootstrapHostState extends State<BootstrapHost> {
  BootstrapState _state = const BootstrapState();
  ProviderContainer? _container;
  Locale? _savedLocale;

  @override
  void initState() {
    super.initState();
    _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    _updateStage(BootstrapStage.initializing, 'Initializing...');

    try {
      final results = await Future.wait([
        initializeHighlighter(),
        SharedPreferences.getInstance(),
        ObjectBoxStore.create(),
      ]);

      final prefs = results[1] as SharedPreferences;
      final database = results[2] as ObjectBoxStore;

      _updateStage(BootstrapStage.preparingApp, 'Preparing app...');

      try {
        final settingsJson = prefs.getString('appSettings');
        if (settingsJson != null) {
          final settings = json.decode(settingsJson) as Map<String, dynamic>;
          final code = settings['localeCode'] as String?;
          if (code != null) _savedLocale = Locale(code);
        }
      } catch (_) {}

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(database),
        ],
      );

      _updateStage(BootstrapStage.initializingServices, 'Initializing services...');
      await container.read(downloadNotificationServiceProvider).init();

      _updateStage(BootstrapStage.configuringServer, 'Configuring server...');
      final servers = await container.read(serversProvider.future);
      final hasOnDevice = servers.any((s) => s.type == ServerType.onDevice);
      if (!hasOnDevice) {
        final server = Server(
          id: 'on-device',
          name: 'On-Device',
          type: ServerType.onDevice,
          host: '',
          port: 0,
          isDefault: false,
          createdAt: DateTime.now(),
          lastConnectedAt: DateTime.now(),
          status: ConnectionStatus.connected,
          iconName: 'strokeRoundedSmartPhone01',
        );
        await container.read(serversProvider.notifier).addServer(server);
      }

      _container = container;
      _updateStage(BootstrapStage.done, 'Ready');
    } catch (e) {
      _state = BootstrapState(
        stage: BootstrapStage.error,
        statusMessage: 'Startup failed',
        error: e,
      );
      if (mounted) setState(() {});
    }
  }

  void _updateStage(BootstrapStage stage, String message) {
    if (!mounted) return;
    setState(() {
      _state = BootstrapState(stage: stage, statusMessage: message);
    });
  }

  @override
  void dispose() {
    _container?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_container != null) {
      return UncontrolledProviderScope(
        container: _container!,
        child: const App(),
      );
    }

    return BootstrapScreen(
      state: _state,
      locale: _savedLocale,
      onRetry: _state.stage == BootstrapStage.error ? _runBootstrap : null,
    );
  }
}
