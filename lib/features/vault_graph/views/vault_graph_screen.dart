import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../vault/data/models/artifact.dart';
import '../../vault/providers/vault_providers.dart';
import '../data/models/vault_connection.dart';
import '../logic/force_simulation.dart';
import '../logic/graph_model.dart';
import '../providers/vault_graph_providers.dart';
import 'components/vault_graph_legend.dart';
import 'components/vault_graph_painter.dart';

/// A force-directed graph of the vault (mobile PRD M4) — artifacts as
/// nodes, `connections` as edges, colored by artifact type, tap-to-open.
///
/// Physics is a from-scratch, deliberately simple simulation (see
/// `../logic/force_simulation.dart`): nodes repel, edges spring toward a
/// target length, and it settles over a fixed number of ticks rather than
/// running indefinitely. Reduced-motion runs the same steps synchronously
/// before first paint instead of animating them (T-M4-12).
///
/// Node/edge data comes from the already-loaded [vaultListProvider] plus
/// [vaultConnectionsProvider] (`GET /api/connections`). Memory nodes are out
/// of scope for this v1 pass — see the module doc comment in
/// `../providers/vault_graph_providers.dart` for why.
class VaultGraphScreen extends ConsumerStatefulWidget {
  const VaultGraphScreen({super.key});

  @override
  ConsumerState<VaultGraphScreen> createState() => _VaultGraphScreenState();
}

class _VaultGraphScreenState extends ConsumerState<VaultGraphScreen>
    with SingleTickerProviderStateMixin {
  static const _nodeCap = 150;
  static const _maxAnimatedTicks = 200;

  bool _built = false;
  List<GraphNode> _nodes = const [];
  List<GraphEdge> _edges = const [];
  GraphSimulation? _simulation;
  bool _truncated = false;

  Ticker? _ticker;
  int _ticksRun = 0;

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _initGraph(
    List<Artifact> artifacts,
    List<VaultConnection> connections,
    bool reduceMotion,
  ) {
    _built = true;

    final sorted = [...artifacts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _truncated = sorted.length > _nodeCap;
    final capped = sorted.take(_nodeCap).toList();

    _nodes = capped
        .map(
          (a) => GraphNode(
            slug: a.slug,
            title: a.title,
            type: a.type,
            artifact: a,
          ),
        )
        .toList();

    final indexBySlug = <String, int>{
      for (var i = 0; i < _nodes.length; i++) _nodes[i].slug: i,
    };

    final edges = <GraphEdge>[];
    final seenPairs = <String>{};
    for (final connection in connections) {
      final aIndex = indexBySlug[connection.aId];
      final bIndex = indexBySlug[connection.bId];
      if (aIndex == null || bIndex == null || aIndex == bIndex) {
        continue; // Can't resolve both endpoints — skip, don't crash.
      }
      final key = aIndex < bIndex ? '$aIndex-$bIndex' : '$bIndex-$aIndex';
      if (!seenPairs.add(key)) continue; // De-dupe parallel edges.
      edges.add(
        GraphEdge(
          aIndex: aIndex,
          bIndex: bIndex,
          isManual: connection.isManual,
        ),
      );
    }
    _edges = edges;

    final side = (500 + _nodes.length * 14.0).clamp(600.0, 2600.0);
    _simulation = GraphSimulation(
      nodeCount: _nodes.length,
      edges: _edges,
      width: side,
      height: side,
    );

    if (reduceMotion || _nodes.length <= 1) {
      _simulation!.runSteps(_maxAnimatedTicks);
    } else {
      _ticker = createTicker(_onTick)..start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _simulation == null) return;
    _simulation!.step();
    _ticksRun++;
    if (_ticksRun >= _maxAnimatedTicks) {
      _ticker?.stop();
    }
    setState(() {});
  }

  void _handleTap(Offset localPosition) {
    final positions = _simulation?.positions;
    if (positions == null) return;
    const hitRadius = 24.0;
    var best = double.infinity;
    int? bestIndex;
    for (var i = 0; i < positions.length; i++) {
      final distance = (positions[i] - localPosition).distance;
      if (distance <= hitRadius && distance < best) {
        best = distance;
        bestIndex = i;
      }
    }
    if (bestIndex == null) return;
    final artifact = _nodes[bestIndex].artifact;
    context.push(AppRoutes.artifactDetail, extra: artifact.slug);
  }

  @override
  Widget build(BuildContext context) {
    final vaultAsync = ref.watch(vaultListProvider);
    final connectionsAsync = ref.watch(vaultConnectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vault Graph')),
      body: vaultAsync.when(
        data: (artifacts) => _buildBody(context, artifacts, connectionsAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(context, err),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Artifact> artifacts,
    AsyncValue<List<VaultConnection>> connectionsAsync,
  ) {
    if (!_built) {
      if (connectionsAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      final connections = connectionsAsync.value ?? const <VaultConnection>[];
      _initGraph(
        artifacts,
        connections,
        MediaQuery.of(context).disableAnimations,
      );
    }

    if (_nodes.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildGraphView(context);
  }

  Widget _buildGraphView(BuildContext context) {
    final simulation = _simulation!;
    final side = simulation.width;

    final typesPresent = <String>[];
    final seenTypes = <String>{};
    for (final node in _nodes) {
      final type = node.type.trim().toLowerCase();
      final normalized = type.isEmpty ? 'html' : type;
      if (seenTypes.add(normalized)) typesPresent.add(normalized);
    }
    typesPresent.sort();

    return Column(
      children: [
        Expanded(
          child: Semantics(
            label:
                '${_nodes.length} artifact${_nodes.length == 1 ? '' : 's'}, '
                '${_edges.length} connection${_edges.length == 1 ? '' : 's'}'
                '${_truncated ? ', showing the 150 newest' : ''}',
            child: InteractiveViewer(
              constrained: false,
              minScale: 0.2,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(400),
              child: SizedBox(
                width: side,
                height: side,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleTap(details.localPosition),
                  child: CustomPaint(
                    size: Size(side, side),
                    painter: VaultGraphPainter(
                      nodes: _nodes,
                      edges: _edges,
                      positions: simulation.positions,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        VaultGraphLegend(typesPresent: typesPresent, truncated: _truncated),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedChartRelationship,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No connections yet',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Save a few artifacts or memorize some chunks and their '
              'connections will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object err) {
    final message = err is HyperVaultApiException
        ? err.message
        : err.toString();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(vaultListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
