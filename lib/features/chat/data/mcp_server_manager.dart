import 'mcp_client.dart';

const exampleMcpServerLabel = 'Example MCP';
const exampleMcpServerUrl = 'local://example-mcp';

class McpServerManager {
  final Map<String, McpClient> _clients = {};
  final Map<String, McpCapabilities> _capabilities = {};
  final Map<String, List<McpTool>> _tools = {};
  final Map<String, String> _serverUrls = {};
  final Set<String> _localExampleServers = {};

  Future<void> addServer(
    String label,
    String url, {
    Map<String, String>? headers,
  }) async {
    if (_clients.containsKey(label)) {
      removeServer(label);
    }

    final client = McpClient(serverUrl: url, headers: headers);

    final capabilities = await client.initialize();
    final tools = await client.listTools();

    _clients[label] = client;
    _capabilities[label] = capabilities;
    _tools[label] = tools;
    _serverUrls[label] = url;
  }

  void removeServer(String label) {
    _clients[label]?.close();
    _clients.remove(label);
    _capabilities.remove(label);
    _tools.remove(label);
    _serverUrls.remove(label);
    _localExampleServers.remove(label);
  }

  void addExampleServer() {
    removeServer(exampleMcpServerLabel);

    _capabilities[exampleMcpServerLabel] = const McpCapabilities(tools: true);
    _tools[exampleMcpServerLabel] = const [
      McpTool(
        name: 'example.echo',
        description: 'Echo a message back from the example MCP server.',
        inputSchema: {
          'type': 'object',
          'properties': {
            'message': {
              'type': 'string',
              'description': 'The message to echo.',
            },
          },
          'required': ['message'],
        },
      ),
      McpTool(
        name: 'example.word_count',
        description: 'Count the words in a text string.',
        inputSchema: {
          'type': 'object',
          'properties': {
            'text': {
              'type': 'string',
              'description': 'The text to count words in.',
            },
          },
          'required': ['text'],
        },
      ),
    ];
    _serverUrls[exampleMcpServerLabel] = exampleMcpServerUrl;
    _localExampleServers.add(exampleMcpServerLabel);
  }

  bool hasServer(String label) =>
      _clients.containsKey(label) || _localExampleServers.contains(label);

  bool hasExampleServer() =>
      _localExampleServers.contains(exampleMcpServerLabel);

  List<McpTool> getTools(String label) => _tools[label] ?? [];

  Map<String, List<McpTool>> get allTools => Map.unmodifiable(_tools);

  McpCapabilities? getCapabilities(String label) => _capabilities[label];

  String? getServerUrl(String label) => _serverUrls[label];

  Future<String> callTool(
    String serverLabel,
    String toolName,
    Map<String, dynamic> args,
  ) async {
    if (_localExampleServers.contains(serverLabel)) {
      return _callExampleTool(toolName, args);
    }

    final client = _clients[serverLabel];
    if (client == null) {
      throw McpException('MCP server not connected: $serverLabel');
    }

    if (!client.isInitialized) {
      await client.initialize();
    }

    return client.callTool(toolName, args);
  }

  Future<String> readResource(String serverLabel, String uri) async {
    final client = _clients[serverLabel];
    if (client == null) {
      throw McpException('MCP server not connected: $serverLabel');
    }

    if (!client.isInitialized) {
      await client.initialize();
    }

    return client.readResource(uri);
  }

  void clear() {
    for (final client in _clients.values) {
      client.close();
    }
    _clients.clear();
    _capabilities.clear();
    _tools.clear();
    _serverUrls.clear();
    _localExampleServers.clear();
  }

  String _callExampleTool(String toolName, Map<String, dynamic> args) {
    switch (toolName) {
      case 'example.echo':
        final message = args['message'];
        if (message is! String) {
          throw McpException('example.echo requires a string message');
        }
        return message;
      case 'example.word_count':
        final text = args['text'];
        if (text is! String) {
          throw McpException('example.word_count requires a string text value');
        }
        final words = text
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .length;
        return words.toString();
      default:
        throw McpException('Example MCP tool not found: $toolName');
    }
  }

  int get serverCount => _tools.length;

  List<String> get serverLabels => _tools.keys.toList();
}
