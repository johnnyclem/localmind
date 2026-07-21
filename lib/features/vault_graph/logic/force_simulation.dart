import 'dart:math';
import 'dart:ui' show Offset;

import 'graph_model.dart';

/// A minimal from-scratch force-directed layout: nodes repel each other
/// (inverse-square, Coulomb-like), edges pull their endpoints toward a
/// target length (a spring), and a weak centering force keeps the whole
/// graph from drifting off-canvas. Not a polished physics engine — a fixed
/// number of [step]s settling to a roughly stable layout is enough for the
/// Vault Graph (mobile PRD M4, T-M4-01).
class GraphSimulation {
  final List<Offset> positions;
  final List<Offset> _velocities;
  final List<GraphEdge> edges;
  final double width;
  final double height;

  static const double _repulsion = 14000;
  static const double _springLength = 90;
  static const double _springStrength = 0.02;
  static const double _centerStrength = 0.012;
  static const double _damping = 0.82;
  static const double _maxSpeed = 40;
  static const double _minDistance = 1;

  final Random _random = Random(1);

  GraphSimulation({
    required int nodeCount,
    required this.edges,
    this.width = 900,
    this.height = 900,
  }) : positions = _seedPositions(nodeCount, width, height),
       _velocities = List<Offset>.filled(nodeCount, Offset.zero);

  /// Golden-angle spiral seeding: spreads nodes evenly from the start so the
  /// simulation converges in far fewer steps than an all-random layout.
  static List<Offset> _seedPositions(int count, double w, double h) {
    final center = Offset(w / 2, h / 2);
    final maxRadius = min(w, h) * 0.38;
    const goldenAngle = 2.399963229728653;
    return List<Offset>.generate(count, (i) {
      final angle = i * goldenAngle;
      final radius = maxRadius * sqrt((i + 1) / max(count, 1));
      return center + Offset(cos(angle), sin(angle)) * radius;
    });
  }

  /// Advances the simulation by one tick.
  void step() {
    final n = positions.length;
    if (n == 0) return;
    final forces = List<Offset>.filled(n, Offset.zero);

    // Repulsion — every pair of nodes pushes the other away.
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        var delta = positions[i] - positions[j];
        var dist = delta.distance;
        if (dist < _minDistance) {
          delta = Offset(
            _random.nextDouble() - 0.5,
            _random.nextDouble() - 0.5,
          );
          dist = _minDistance;
        }
        final magnitude = _repulsion / (dist * dist);
        final push = delta / dist * magnitude;
        forces[i] += push;
        forces[j] -= push;
      }
    }

    // Attraction — connected nodes pull toward a target edge length.
    for (final edge in edges) {
      if (edge.aIndex >= n || edge.bIndex >= n) continue;
      var delta = positions[edge.bIndex] - positions[edge.aIndex];
      var dist = delta.distance;
      if (dist < _minDistance) dist = _minDistance;
      final diff = dist - _springLength;
      final pull = delta / dist * (diff * _springStrength);
      forces[edge.aIndex] += pull;
      forces[edge.bIndex] -= pull;
    }

    // Weak centering so the graph settles near the middle of the canvas.
    final center = Offset(width / 2, height / 2);
    for (var i = 0; i < n; i++) {
      forces[i] += (center - positions[i]) * _centerStrength;
    }

    // Integrate.
    for (var i = 0; i < n; i++) {
      var velocity = (_velocities[i] + forces[i]) * _damping;
      final speed = velocity.distance;
      if (speed > _maxSpeed) {
        velocity = velocity / speed * _maxSpeed;
      }
      _velocities[i] = velocity;
      positions[i] = positions[i] + velocity;
    }
  }

  /// Runs [count] steps synchronously — used for the reduced-motion path
  /// (compute the resting layout before first paint instead of animating).
  void runSteps(int count) {
    for (var i = 0; i < count; i++) {
      step();
    }
  }
}
