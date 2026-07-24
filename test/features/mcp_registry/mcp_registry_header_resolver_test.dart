import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/mcp_registry/data/mcp_registry_header_resolver.dart';
import 'package:localmind/features/mcp_registry/data/models/mcp_registry_server.dart';

void main() {
  group('resolveMcpHeaderValues', () {
    test('uses the supplied value for a required secret header', () {
      final result = resolveMcpHeaderValues(
        [
          const McpRegistryVariable(
            name: 'Authorization',
            isRequired: true,
            isSecret: true,
          ),
        ],
        {'Authorization': 'Bearer abc123'},
      );

      expect(result, {'Authorization': 'Bearer abc123'});
    });

    test('falls back to the declared default when nothing is supplied', () {
      final result = resolveMcpHeaderValues(
        [
          const McpRegistryVariable(
            name: 'X-API-Version',
            defaultValue: 'v1',
          ),
        ],
        {},
      );

      expect(result, {'X-API-Version': 'v1'});
    });

    test('omits an optional header with no value and no default', () {
      final result = resolveMcpHeaderValues(
        [const McpRegistryVariable(name: 'X-Request-ID', isRequired: false)],
        {},
      );

      expect(result, isEmpty);
    });

    test('throws when a required header has no value and no default', () {
      expect(
        () => resolveMcpHeaderValues(
          [const McpRegistryVariable(name: 'Authorization', isRequired: true)],
          {},
        ),
        throwsA(isA<McpRegistryHeaderException>()),
      );
    });

    test('ignores extra supplied keys the server never declared', () {
      final result = resolveMcpHeaderValues(
        [const McpRegistryVariable(name: 'X-Client-ID')],
        {'X-Client-ID': 'abc', 'Unrelated': 'nope'},
      );

      expect(result, {'X-Client-ID': 'abc'});
    });
  });
}
