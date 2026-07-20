import 'package:flutter/material.dart';

import '../../logic/graph_model.dart';

/// Legend row listing only the artifact types actually present in the
/// graph, plus the manual/auto edge-style swatches (mobile PRD M4,
/// T-M4-09), and a footer note about the 150-node cap / gesture hints.
class VaultGraphLegend extends StatelessWidget {
  final List<String> typesPresent;
  final bool truncated;

  const VaultGraphLegend({
    super.key,
    required this.typesPresent,
    required this.truncated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final type in typesPresent)
                _swatch(
                  color: colorForArtifactType(type),
                  label: type,
                  style: labelStyle,
                ),
              _edgeSwatch(
                color: manualEdgeColor,
                dashed: false,
                label: 'manual',
                style: labelStyle,
              ),
              _edgeSwatch(
                color: autoEdgeColor,
                dashed: true,
                label: 'auto',
                style: labelStyle,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            truncated
                ? 'Showing your 150 newest · pinch to zoom, drag to pan'
                : 'Tap a node to open it · pinch to zoom, drag to pan',
            style: labelStyle,
          ),
        ],
      ),
    );
  }

  Widget _swatch({
    required Color color,
    required String label,
    TextStyle? style,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }

  Widget _edgeSwatch({
    required Color color,
    required bool dashed,
    required String label,
    TextStyle? style,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 10,
          child: CustomPaint(
            painter: _EdgeSwatchPainter(color: color, dashed: dashed),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}

class _EdgeSwatchPainter extends CustomPainter {
  final Color color;
  final bool dashed;

  const _EdgeSwatchPainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + 3, y), paint);
      x += 6;
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeSwatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}
