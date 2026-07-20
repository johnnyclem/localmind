import '../data/models/hv_mcp_server.dart';

/// Draft state model for the tools console: [persisted] mirrors the last
/// known server-side truth, [draft] is what the master/per-tool switches
/// mutate locally. Nothing reaches the API until Compile — mirrors the web
/// console's draft/compile model (spec T-M11-02).
class HvMcpConsoleState {
  final List<HvMcpServer> persisted;
  final List<HvMcpServer> draft;

  const HvMcpConsoleState({this.persisted = const [], this.draft = const []});

  /// True when any draft server differs from its persisted counterpart.
  bool get dirty => pendingChangeCount > 0;

  /// Count of individual toggle differences between [draft] and [persisted]
  /// — a server's enabled flip counts once, each tool toggled counts once.
  int get pendingChangeCount {
    final byId = {for (final s in persisted) s.id: s};
    var count = 0;
    for (final d in draft) {
      final p = byId[d.id];
      if (p == null) continue;
      if (p.enabled != d.enabled) count++;
      final pSet = p.disabledTools.toSet();
      final dSet = d.disabledTools.toSet();
      count += pSet.difference(dSet).length + dSet.difference(pSet).length;
    }
    return count;
  }

  HvMcpServer? draftServer(String id) {
    for (final s in draft) {
      if (s.id == id) return s;
    }
    return null;
  }
}
