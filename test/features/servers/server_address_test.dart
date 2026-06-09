import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/features/servers/data/models/server.dart';

void main() {
  group('Server address parsing', () {
    test('builds baseUrl for a bare host and port', () {
      final server = Server(
        id: '1',
        name: 'Local',
        type: ServerType.openAICompatible,
        host: 'localhost',
        port: 8080,
        createdAt: DateTime(2026, 1, 1),
        lastConnectedAt: DateTime(2026, 1, 1),
      );

      expect(server.baseUrl, 'http://localhost:8080');
    });

    test('preserves an explicit http URL without doubling the port', () {
      final server = Server(
        id: '1',
        name: 'Local',
        type: ServerType.openAICompatible,
        host: 'http://localhost:8080',
        port: 1234,
        createdAt: DateTime(2026, 1, 1),
        lastConnectedAt: DateTime(2026, 1, 1),
      );

      expect(server.baseUrl, 'http://localhost:8080');
      expect(server.displayAddress, 'http://localhost:8080');
    });

    test('accepts https URLs and keeps the configured port when missing', () {
      final server = Server(
        id: '1',
        name: 'Secure',
        type: ServerType.openAICompatible,
        host: 'https://localhost',
        port: 8443,
        createdAt: DateTime(2026, 1, 1),
        lastConnectedAt: DateTime(2026, 1, 1),
      );

      expect(server.baseUrl, 'https://localhost:8443');
      expect(server.displayAddress, 'https://localhost:8443');
    });

    test('keeps a host that already includes a port', () {
      final server = Server(
        id: '1',
        name: 'Local',
        type: ServerType.openAICompatible,
        host: 'localhost:8080',
        port: 1234,
        createdAt: DateTime(2026, 1, 1),
        lastConnectedAt: DateTime(2026, 1, 1),
      );

      expect(server.baseUrl, 'http://localhost:8080');
      expect(server.displayAddress, 'localhost:8080');
    });
  });
}
