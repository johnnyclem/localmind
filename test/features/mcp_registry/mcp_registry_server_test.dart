import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/mcp_registry/data/models/mcp_registry_server.dart';

void main() {
  group('McpRegistryServer.fromJson', () {
    test('parses an npm stdio package with environment variables', () {
      final server = McpRegistryServer.fromJson({
        'server': {
          'name': 'io.example.com/search-server',
          'description': 'Search integration server',
          'title': 'Search',
          'version': '1.0.0',
          'packages': [
            {
              'registryType': 'npm',
              'identifier': '@example/search-mcp',
              'version': '1.0.0',
              'transport': {'type': 'stdio'},
              'environmentVariables': [
                {
                  'name': 'API_KEY',
                  'description': 'Search API authentication key',
                  'isRequired': true,
                  'isSecret': true,
                },
              ],
            },
          ],
        },
      });

      expect(server.name, 'io.example.com/search-server');
      expect(server.displayName, 'Search');
      expect(server.hasRemote, isFalse);
      expect(server.hasStdioOnly, isTrue);
      expect(server.isInstallable, isFalse);
      expect(server.packages, hasLength(1));
      expect(server.packages.first.environmentVariables.single.isSecret, isTrue);
    });

    test('parses an SSE remote with a required secret header', () {
      final server = McpRegistryServer.fromJson({
        'server': {
          'name': 'io.example.com/auth-remote-server',
          'description': 'Secured remote authentication server',
          'version': '2.0.0',
          'remotes': [
            {
              'type': 'sse',
              'url': 'https://auth-service.example.com/events',
              'headers': [
                {
                  'name': 'Authorization',
                  'description': 'Bearer token',
                  'isRequired': true,
                  'isSecret': true,
                },
                {
                  'name': 'X-Client-ID',
                  'description': 'Client identifier',
                  'isRequired': true,
                  'isSecret': false,
                },
              ],
            },
          ],
        },
      });

      expect(server.hasRemote, isTrue);
      expect(server.isInstallable, isTrue);
      final remote = server.primaryRemote!;
      expect(remote.type, 'sse');
      expect(remote.hasDeclaredSecretHeaders, isTrue);
      expect(remote.headers, hasLength(2));
    });

    test('prefers streamable-http over sse when both are present', () {
      final server = McpRegistryServer.fromJson({
        'server': {
          'name': 'io.example.com/multi-transport',
          'description': '',
          'version': '1.0.0',
          'remotes': [
            {'type': 'sse', 'url': 'https://example.com/sse'},
            {'type': 'streamable-http', 'url': 'https://example.com/http'},
          ],
        },
      });

      expect(server.primaryRemote!.type, 'streamable-http');
    });

    test('falls back to the short name when no title is set', () {
      final server = McpRegistryServer.fromJson({
        'server': {
          'name': 'io.github.acme/widget-server',
          'description': '',
          'version': '1.0.0',
        },
      });

      expect(server.displayName, 'widget-server');
    });

    test('reads registry status from _meta', () {
      final server = McpRegistryServer.fromJson({
        'server': {
          'name': 'io.example/status-server',
          'description': '',
          'version': '1.0.0',
        },
        '_meta': {
          'io.modelcontextprotocol.registry/official': {
            'status': 'active',
            'publishedAt': '2025-01-01T10:30:00Z',
          },
        },
      });

      expect(server.status, 'active');
      expect(server.publishedAt, DateTime.utc(2025, 1, 1, 10, 30));
    });

    test('accepts an unwrapped server object defensively', () {
      final server = McpRegistryServer.fromJson({
        'name': 'io.example/unwrapped',
        'description': 'no server/_meta wrapper',
        'version': '1.0.0',
      });

      expect(server.name, 'io.example/unwrapped');
    });
  });

  group('McpRegistryPage.fromJson', () {
    test('parses servers and pagination metadata', () {
      final page = McpRegistryPage.fromJson({
        'servers': [
          {
            'server': {
              'name': 'io.example/one',
              'description': '',
              'version': '1.0.0',
            },
          },
        ],
        'metadata': {'nextCursor': 'abc123', 'count': 1},
      });

      expect(page.servers, hasLength(1));
      expect(page.nextCursor, 'abc123');
    });

    test('nextCursor is null on the last page', () {
      final page = McpRegistryPage.fromJson({
        'servers': <Map<String, dynamic>>[],
        'metadata': {'count': 0},
      });

      expect(page.servers, isEmpty);
      expect(page.nextCursor, isNull);
    });
  });
}
