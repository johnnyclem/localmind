import 'dart:math';

import 'package:flutter/material.dart';

import '../../logic/graph_model.dart';

/// Renders the settled/settling graph: edges first (manual solid, auto
/// dashed), then nodes as glowing circles with a truncated title label
/// underneath (mobile PRD M4, T-M4-03/T-M4-05).
class VaultGraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<Offset> positions;
  final double nodeRadius;

  VaultGraphPainter({
    required this.nodes,
    required this.edges,
    required this.positions,
    this.nodeRadius = 9,
  });

  static final Paint _manualPaint = Paint()
    ..color = manualEdgeColor.withValues(alpha: 0.55)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;

  static final Paint _autoPaint = Paint()
    ..color = autoEdgeColor.withValues(alpha: 0.35)
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      if (edge.aIndex >= positions.length || edge.bIndex >= positions.length) {
        continue;
      }
      final p1 = positions[edge.aIndex];
      final p2 = positions[edge.bIndex];
      if (edge.isManual) {
        canvas.drawLine(p1, p2, _manualPaint);
      } else {
        _drawDashedLine(canvas, p1, p2, _autoPaint);
      }
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < nodes.length && i < positions.length; i++) {
      final node = nodes[i];
      final pos = positions[i];
      final color = colorForArtifactType(node.type);

      canvas.drawCircle(
        pos,
        nodeRadius + 5,
        Paint()..color = color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(pos, nodeRadius, Paint()..color = color);
      canvas.drawCircle(
        pos,
        nodeRadius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      final label = node.title.length > 25
          ? '${node.title.substring(0, 25)}…'
          : node.title;
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
      );
      textPainter.layout(maxWidth: 110);
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy + nodeRadius + 4),
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 4,
    double gapLength = 3,
  }) {
    final total = (end - start).distance;
    if (total <= 0) return;
    final direction = (end - start) / total;
    var covered = 0.0;
    var drawing = true;
    var current = start;
    while (covered < total) {
      final segment = min(drawing ? dashLength : gapLength, total - covered);
      final next = current + direction * segment;
      if (drawing) canvas.drawLine(current, next, paint);
      current = next;
      covered += segment;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant VaultGraphPainter oldDelegate) => true;
}
