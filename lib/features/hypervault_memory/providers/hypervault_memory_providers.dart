import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hypervault/providers/hypervault_providers.dart';
import '../data/hypervault_memory_service.dart';
import '../data/hypervault_mind_service.dart';
import '../data/models/hv_memory_detail.dart';
import '../data/models/hv_memory_recall_result.dart';
import '../data/models/hv_memory_revision.dart';
import '../data/models/hv_memory_summary.dart';
import '../data/models/hv_mind_branch.dart';
import '../data/models/hv_mind_commit.dart';

final hyperVaultMemoryServiceProvider = Provider<HypervaultMemoryService>((
  ref,
) {
  return HypervaultMemoryService(ref.read(hyperVaultApiClientProvider));
});

final hyperVaultMindServiceProvider = Provider<HypervaultMindService>((ref) {
  return HypervaultMindService(ref.read(hyperVaultApiClientProvider));
});

/// The checked-out branch driving every memory/mind call on the Memory
/// screen. `null` means the default branch (`main`) — omitted from query
/// params, per api-contract.
final hyperVaultActiveBranchProvider =
    NotifierProvider<HyperVaultActiveBranchNotifier, String?>(
      HyperVaultActiveBranchNotifier.new,
    );

class HyperVaultActiveBranchNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void checkout(String? branch) {
    state = (branch == null || branch == 'main' || branch.isEmpty)
        ? null
        : branch;
  }
}

/// `GET /api/mind/branches` for the branch-switcher chip row.
final hyperVaultMindBranchesProvider = FutureProvider<List<HvMindBranch>>((
  ref,
) async {
  final service = ref.read(hyperVaultMindServiceProvider);
  return service.branches();
});

/// The wiki index for the active branch (browse mode).
final hyperVaultMemoryBrowseProvider = FutureProvider<List<HvMemorySummary>>((
  ref,
) async {
  final branch = ref.watch(hyperVaultActiveBranchProvider);
  final service = ref.read(hyperVaultMemoryServiceProvider);
  return service.browse(branch: branch);
});

final hyperVaultMemorySearchQueryProvider =
    NotifierProvider<HyperVaultMemorySearchQueryNotifier, String>(
      HyperVaultMemorySearchQueryNotifier.new,
    );

class HyperVaultMemorySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
  void clear() => state = '';
}

/// Instant local filter over the loaded browse list (T-M6-02) — a substring
/// rank over title/summary/tags/source, mirroring web `scoreRecall` closely
/// enough to feel instant before the network responds.
final hyperVaultMemoryLocalFilterProvider = Provider<List<HvMemorySummary>>((
  ref,
) {
  final query = ref
      .watch(hyperVaultMemorySearchQueryProvider)
      .trim()
      .toLowerCase();
  final memories = ref.watch(hyperVaultMemoryBrowseProvider).value ?? const [];
  if (query.isEmpty) return memories;
  return memories.where((m) {
    if (m.title.toLowerCase().contains(query)) return true;
    if (m.summary.toLowerCase().contains(query)) return true;
    if (m.source.toLowerCase().contains(query)) return true;
    return m.tags.any((t) => t.toLowerCase().contains(query));
  }).toList();
});

enum HvRecallStatus { idle, recalling, done, error }

class HvRecallState {
  final HvRecallStatus status;
  final HvMemoryRecallResponse? response;
  final String? error;

  const HvRecallState({required this.status, this.response, this.error});

  static const idle = HvRecallState(status: HvRecallStatus.idle);

  bool get isRecalling => status == HvRecallStatus.recalling;
}

/// Debounced (~300ms) server recall (T-M6-03). Queries under 2 chars stay
/// idle (local filter only). A monotonic request generation lets a fast
/// retype invalidate an in-flight response without needing request
/// cancellation support from [HyperVaultApiClient].
final hyperVaultMemoryRecallProvider =
    NotifierProvider<HyperVaultMemoryRecallNotifier, HvRecallState>(
      HyperVaultMemoryRecallNotifier.new,
    );

class HyperVaultMemoryRecallNotifier extends Notifier<HvRecallState> {
  Timer? _debounce;
  int _generation = 0;

  @override
  HvRecallState build() {
    ref.listen<String>(hyperVaultMemorySearchQueryProvider, (previous, next) {
      _onQueryChanged(next);
    });
    // A branch checkout re-scopes recall (main is hybrid, branches are
    // lexical-only) — re-run the current query against the new branch.
    ref.listen<String?>(hyperVaultActiveBranchProvider, (previous, next) {
      if (previous != next) refresh();
    });
    ref.onDispose(() => _debounce?.cancel());
    return HvRecallState.idle;
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _generation++;
      state = HvRecallState.idle;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _recall(trimmed);
    });
  }

  Future<void> _recall(String query) async {
    final myGeneration = ++_generation;
    state = HvRecallState(
      status: HvRecallStatus.recalling,
      response: state.response,
    );
    try {
      final service = ref.read(hyperVaultMemoryServiceProvider);
      final branch = ref.read(hyperVaultActiveBranchProvider);
      final response = await service.recall(query: query, branch: branch);
      if (myGeneration != _generation) return; // stale — a newer query won
      state = HvRecallState(status: HvRecallStatus.done, response: response);
    } catch (e) {
      if (myGeneration != _generation) return;
      state = HvRecallState(
        status: HvRecallStatus.error,
        response: state.response,
        error: e.toString(),
      );
    }
  }

  /// Re-runs the current query against the (possibly just-switched) branch.
  void refresh() {
    final query = ref.read(hyperVaultMemorySearchQueryProvider).trim();
    if (query.length >= 2) _recall(query);
  }
}

/// `GET /api/memories/[id]?branch=` for the detail screen.
final hyperVaultMemoryDetailProvider = FutureProvider.autoDispose
    .family<HvMemoryDetail, String>((ref, id) async {
      final branch = ref.watch(hyperVaultActiveBranchProvider);
      final service = ref.read(hyperVaultMemoryServiceProvider);
      return service.getDetail(id, branch: branch);
    });

/// `GET /api/memories/[id]/history` for the history timeline.
final hyperVaultMemoryHistoryProvider = FutureProvider.autoDispose
    .family<List<HvMemoryRevision>, String>((ref, id) async {
      final service = ref.read(hyperVaultMemoryServiceProvider);
      return service.history(id, limit: 100);
    });

/// `GET /api/mind/commits?branch=` for a given branch's log strip.
final hyperVaultMindCommitsProvider = FutureProvider.autoDispose
    .family<List<HvMindCommit>, String?>((ref, branch) async {
      final service = ref.read(hyperVaultMindServiceProvider);
      return service.commits(branch: branch, limit: 50);
    });

/// UTF-8 byte length of memory content, for client-side cap enforcement
/// against `capabilities.limits.memoryBytes`.
int hvUtf8ByteLength(String text) => utf8.encode(text).length;
