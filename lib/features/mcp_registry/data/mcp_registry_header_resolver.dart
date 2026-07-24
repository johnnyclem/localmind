import 'models/mcp_registry_server.dart';

/// Thrown when a remote's declared headers can't be satisfied.
class McpRegistryHeaderException implements Exception {
  final String message;
  const McpRegistryHeaderException(this.message);

  @override
  String toString() => message;
}

/// Resolves the concrete header map to attach to every request for a
/// registry remote, given what the server.json declares and what the user
/// supplied (e.g. via the install dialog's text fields). Pulled out as a
/// pure function — independent of Riverpod/network — so it's directly unit
/// testable; [McpRegistryInstallService] just calls this.
///
/// Falls back to a declared `default` when the user left a field blank;
/// throws if a *required* header ends up with no value either way. Headers
/// the server didn't declare at all are never attached, even if [supplied]
/// carries extra keys (whatever collected them was already scoped to the
/// declared list).
Map<String, String> resolveMcpHeaderValues(
  List<McpRegistryVariable> declared,
  Map<String, String> supplied,
) {
  final headers = <String, String>{};
  for (final variable in declared) {
    final value = supplied[variable.name] ?? variable.defaultValue;
    if (value == null || value.isEmpty) {
      if (variable.isRequired) {
        throw McpRegistryHeaderException(
          'The "${variable.name}" header is required for this server.',
        );
      }
      continue;
    }
    headers[variable.name] = value;
  }
  return headers;
}
