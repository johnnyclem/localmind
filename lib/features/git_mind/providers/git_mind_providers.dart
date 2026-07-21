import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/hypervault_providers.dart';
import '../data/git_mind_api_service.dart';
import '../data/models/git_mind_models.dart';

final gitMindApiServiceProvider = Provider<GitMindApiService>((ref) {
  return GitMindApiService(ref.watch(hypervaultClientProvider));
});

/// Owns the branch list (`GET /api/mind/branches`, T-M7-01/02/03).
class MindBranchesNotifier extends AsyncNotifier<List<MindBranch>> {
  @override
  Future<List<MindBranch>> build() async {
    return ref.read(gitMindApiServiceProvider).fetchBranches();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(gitMindApiServiceProvider).fetchBranches(),
    );
  }
}

final mindBranchesProvider =
    AsyncNotifierProvider<MindBranchesNotifier, List<MindBranch>>(
      MindBranchesNotifier.new,
    );

/// The branch currently "checked out" on the Git-mind screen. Selecting a
/// chip only updates this local state (no navigation) — the commit log and
/// every other panel below simply re-reads with `?branch=<selected>`.
/// Riverpod 3.x dropped `StateProvider`, so this is a plain `Notifier<String>`
/// exposing a `set` mutator, mirroring `on_device_providers.dart`'s
/// convention for simple mutable UI state.
class SelectedGitMindBranchNotifier extends Notifier<String> {
  @override
  String build() => 'main';

  void set(String branch) => state = branch;
}

final selectedGitMindBranchProvider =
    NotifierProvider<SelectedGitMindBranchNotifier, String>(
      SelectedGitMindBranchNotifier.new,
    );

/// Owns the commit log for one branch (`GET /api/mind/commits?branch=`,
/// T-M7-10). One instance per branch name via the family's constructor arg,
/// mirroring `MemoryDetailNotifier`'s convention elsewhere in the app.
class MindCommitsNotifier extends AsyncNotifier<CommitLog> {
  final String branch;

  MindCommitsNotifier(this.branch);

  @override
  Future<CommitLog> build() async {
    return ref.read(gitMindApiServiceProvider).fetchCommits(branch: branch);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(gitMindApiServiceProvider).fetchCommits(branch: branch),
    );
  }
}

final mindCommitsProvider =
    AsyncNotifierProvider.family<MindCommitsNotifier, CommitLog, String>(
      MindCommitsNotifier.new,
    );

/// Owns one memory's revision history (`GET /api/memories/[id]/history`,
/// T-M7-06) for the History/diff sheet.
class MemoryHistoryNotifier extends AsyncNotifier<MemoryHistory> {
  final String memoryId;

  MemoryHistoryNotifier(this.memoryId);

  @override
  Future<MemoryHistory> build() async {
    return ref.read(gitMindApiServiceProvider).fetchHistory(memoryId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(gitMindApiServiceProvider).fetchHistory(memoryId),
    );
  }
}

final memoryHistoryProvider =
    AsyncNotifierProvider.family<MemoryHistoryNotifier, MemoryHistory, String>(
      MemoryHistoryNotifier.new,
    );
