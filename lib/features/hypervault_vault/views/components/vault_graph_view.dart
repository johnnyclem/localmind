import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/hv_vault_format.dart';
import '../../data/models/hv_artifact.dart';
import '../../data/models/hv_connection.dart';

/// Hand-rolled node-link visualization of the vault (docs/mobile/prd/
/// 04-vault-graph.md): a headless force-directed layout settled once (no
/// live churn — reduced-motion by construction), rendered with
/// [InteractiveViewer] for pinch-zoom/pan and plain widgets per node so hit
/// testing is free. Capped at 150 nodes; edges resolve only when this
/// device has already learned both endpoints' database ids (see
/// `HvVaultCache` — the vault-artifacts list endpoint doesn't expose `id`,
/// so fresh installs may show nodes with no edges until the user Connects a
/// few things from this app).
class VaultGraphView extends StatefulWidget {
  final List<HvArtifact> artifacts;
  final HvConnectionsData connections;
  final String? Function(String slug) idForSlug;
  final void Function(String slug) onTapArtifact;

  static const nodeCap = 150;

  const VaultGraphView({
    super.key,
    required this.artifacts,
    required this.connections,
    required this.idForSlug,
    required this.onTapArtifact,
  });

  @override
  State<VaultGraphView> createState() => _VaultGraphViewState();
}

class _Edge {
  final String aSlug;
  final String bSlug;
  final bool manual;
  const _Edge(this.aSlug, this.bSlug, this.manual);
}

class _VaultGraphViewState extends State<VaultGraphView> {
  Map<String, Offset> _positions = {};
  double _width = 800;
  double _height = 800;
  List<_Edge> _edges = [];
  List<HvArtifact> _nodes = [];

  @override
  void initState() {
    super.initState();
    _layout();
  }

  @override
  void didUpdateWidget(covariant VaultGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artifacts != widget.artifacts ||
        oldWidget.connections != widget.connections) {
      _layout();
    }
  }

  void _layout() {
    final nodes = widget.artifacts.take(VaultGraphView.nodeCap).toList();
    final slugs = nodes.map((a) => a.slug).toSet();

    // Resolve artifact-artifact edges by database id → slug where known;
    // memory edges are out of scope until the memory wiki (M6) ships.
    final idToSlug = <String, String>{};
    for (final slug in slugs) {
      final id = widget.idForSlug(slug);
      if (id != null) idToSlug[id] = slug;
    }
    final edges = <_Edge>[];
    for (final edge in widget.connections.connections) {
      final aSlug = idToSlug[edge.aId];
      final bSlug = idToSlug[edge.bId];
      if (aSlug != null && bSlug != null && aSlug != bSlug) {
        edges.add(_Edge(aSlug, bSlug, edge.isManual));
      }
    }

    final size = max(600.0, sqrt(nodes.length.clamp(1, 999)) * 130.0);
    final positions = _forceLayout(
      nodes.map((a) => a.slug).toList(),
      edges.map((e) => (e.aSlug, e.bSlug)).toList(),
      width: size,
      height: size,
    );

    setState(() {
      _nodes = nodes;
      _edges = edges;
      _positions = positions;
      _width = size;
      _height = size;
    });
  }

  Map<String, Offset> _forceLayout(
    List<String> ids,
    List<(String, String)> edges, {
    required double width,
    required double height,
  }) {
    final rnd = Random(7);
    final pos = <String, Offset>{
      for (final id in ids)
        id: Offset(
          width / 2 + (rnd.nextDouble() - 0.5) * width * 0.8,
          height / 2 + (rnd.nextDouble() - 0.5) * height * 0.8,
        ),
    };
    if (ids.length <= 1) return pos;

    final k = sqrt((width * height) / ids.length);
    const iterations = 120;
    for (var iter = 0; iter < iterations; iter++) {
      final disp = {for (final id in ids) id: Offset.zero};

      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final a = ids[i], b = ids[j];
          var delta = pos[a]! - pos[b]!;
          var dist = delta.distance;
          if (dist < 0.01) {
            delta = Offset(rnd.nextDouble() - 0.5, rnd.nextDouble() - 0.5);
            dist = 0.01;
          }
          final force = (k * k) / dist;
          final d = delta / dist * force;
          disp[a] = disp[a]! + d;
          disp[b] = disp[b]! - d;
        }
      }

      for (final e in edges) {
        if (!pos.containsKey(e.$1) || !pos.containsKey(e.$2)) continue;
        final delta = pos[e.$1]! - pos[e.$2]!;
        final dist = delta.distance < 0.01 ? 0.01 : delta.distance;
        final force = (dist * dist) / k;
        final d = delta / dist * force;
        disp[e.$1] = disp[e.$1]! - d;
        disp[e.$2] = disp[e.$2]! + d;
      }

      final temp = width * 0.06 * (1 - iter / iterations) + 0.5;
      for (final id in ids) {
        final d = disp[id]!;
        final len = d.distance < 0.01 ? 0.01 : d.distance;
        final capped = d / len * min(len, temp);
        var next = pos[id]! + capped;
        next = Offset(
          next.dx.clamp(30, width - 30),
          next.dy.clamp(30, height - 30),
        );
        pos[id] = next;
      }
    }
    return pos;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.artifacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Save a few artifacts and their connections will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      );
    }

    final truncated = widget.artifacts.length > VaultGraphView.nodeCap;
    final typesPresent = _nodes.map((a) => a.type.toLowerCase()).toSet();

    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.2,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(300),
            child: SizedBox(
              width: _width,
              height: _height,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(_width, _height),
                    painter: _EdgePainter(edges: _edges, positions: _positions),
                  ),
                  for (final node in _nodes)
                    if (_positions[node.slug] != null)
                      _buildNode(context, node, _positions[node.slug]!),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final type in typesPresent) _LegendDot(color: hvArtifactTypeColor(type), label: type),
              const _LegendLine(color: Color(0xFF8B5CF6), dashed: false, label: 'manual'),
              const _LegendLine(color: Color(0xFF22D3EE), dashed: true, label: 'auto'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            truncated
                ? 'Showing your ${VaultGraphView.nodeCap} newest · pinch to zoom, drag to pan'
                : 'Tap a node to open it · pinch to zoom, drag to pan',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }

  Widget _buildNode(BuildContext context, HvArtifact node, Offset pos) {
    const radius = 16.0;
    final color = hvArtifactTypeColor(node.type, isJsx: node.isJsx);
    final label = node.title.length > 25 ? '${node.title.substring(0, 25)}…' : node.title;

    return Positioned(
      left: pos.dx - 28,
      top: pos.dy - radius,
      width: 56,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTapArtifact(node.slug),
        child: Column(
          children: [
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  final List<_Edge> edges;
  final Map<String, Offset> positions;

  _EdgePainter({required this.edges, required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final a = positions[edge.aSlug];
      final b = positions[edge.bSlug];
      if (a == null || b == null) continue;
      final paint = Paint()
        ..strokeWidth = edge.manual ? 1.6 : 1.0
        ..color = edge.manual
            ? const Color(0xFF8B5CF6).withValues(alpha: 0.55)
            : const Color(0xFF22D3EE).withValues(alpha: 0.35);
      if (edge.manual) {
        canvas.drawLine(a, b, paint);
      } else {
        _drawDashedLine(canvas, a, b, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashWidth = 3.0;
    const gapWidth = 3.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final direction = (b - a) / total;
    var covered = 0.0;
    var draw = true;
    var current = a;
    while (covered < total) {
      final step = draw ? dashWidth : gapWidth;
      final next = current + direction * min(step, total - covered);
      if (draw) canvas.drawLine(current, next, paint);
      current = next;
      covered += step;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) {
    return oldDelegate.edges != edges || oldDelegate.positions != positions;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _LegendLine extends StatelessWidget {
  final Color color;
  final bool dashed;
  final String label;
  const _LegendLine({required this.color, required this.dashed, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 2,
          child: CustomPaint(painter: _LinePreviewPainter(color: color, dashed: dashed)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _LinePreviewPainter extends CustomPainter {
  final Color color;
  final bool dashed;
  const _LinePreviewPainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(min(x + 3, size.width), size.height / 2), paint);
      x += 6;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePreviewPainter oldDelegate) => false;
}
