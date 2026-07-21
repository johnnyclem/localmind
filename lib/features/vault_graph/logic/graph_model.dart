import 'package:flutter/material.dart';

import '../../vault/data/models/artifact.dart';

/// One artifact rendered as a node in the Vault Graph (mobile PRD M4).
class GraphNode {
  final String slug;
  final String title;
  final String type;
  final Artifact artifact;

  const GraphNode({
    required this.slug,
    required this.title,
    required this.type,
    required this.artifact,
  });
}

/// One resolved edge between two [GraphNode]s, referenced by index into the
/// node list the graph was built from.
class GraphEdge {
  final int aIndex;
  final int bIndex;
  final bool isManual;

  const GraphEdge({
    required this.aIndex,
    required this.bIndex,
    required this.isManual,
  });
}

/// Node colors by lowercased artifact `type`, per the mobile PRD: html and
/// any unrecognized type fall back to blue. Kept byte-for-byte with the web
/// (`components/vault-graph.tsx`) for the types this epic scopes to.
const _reactColor = Color(0xFF8B5CF6);
const _gameColor = Color(0xFFF472B6);
const _reportColor = Color(0xFFFBBF24);
const _defaultColor = Color(0xFF60A5FA);

Color colorForArtifactType(String type) {
  switch (type.trim().toLowerCase()) {
    case 'react':
    case 'jsx':
      return _reactColor;
    case 'game':
      return _gameColor;
    case 'report':
      return _reportColor;
    default:
      return _defaultColor;
  }
}

/// Manual edges render solid purple, auto edges render dashed cyan — see
/// `VaultGraphPainter`.
const manualEdgeColor = Color(0xFF8B5CF6);
const autoEdgeColor = Color(0xFF22D3EE);
