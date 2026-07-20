import '../../hypervault/data/hypervault_api_client.dart';
import 'models/hv_mind_branch.dart';
import 'models/hv_mind_commit.dart';
import 'models/hv_mind_diff.dart';
import 'models/hv_mind_merge.dart';

/// Wraps the git-for-a-mind endpoints (`/api/mind/*`) — branches, commits,
/// diff, and merge. See docs/mobile/prd/07-git-mind.md and api-contract.md
/// `Git-for-a-Mind`.
class HypervaultMindService {
  final HyperVaultApiClient _client;

  HypervaultMindService(this._client);

  /// `GET /api/mind/branches`.
  Future<List<HvMindBranch>> branches() async {
    final json = await _client.get('/api/mind/branches');
    return ((json['branches'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => HvMindBranch.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// `POST /api/mind/branches` — fork a new branch. Throws [HvApiError]
  /// 400 (bad name) / 409 (exists) / 404 (bad `from`).
  Future<HvMindBranch> createBranch({
    required String name,
    String? from,
  }) async {
    final json = await _client.post(
      '/api/mind/branches',
      body: {'name': name, if (from != null && from.isNotEmpty) 'from': from},
    );
    return HvMindBranch(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? name,
      isDefault: false,
      headCommitId: json['head_commit_id'] as String?,
      memoryCount: 0,
    );
  }

  /// `DELETE /api/mind/branches/[name]`. Throws [HvApiError] 400 (default
  /// branch) / 409 (in use by a child branch).
  Future<void> deleteBranch(String name) async {
    await _client.delete('/api/mind/branches/${Uri.encodeComponent(name)}');
  }

  /// `GET /api/mind/commits?branch=&limit=` — `git log` for the mind.
  Future<List<HvMindCommit>> commits({String? branch, int? limit}) async {
    final json = await _client.get(
      '/api/mind/commits',
      query: {
        if (branch != null && branch.isNotEmpty) 'branch': branch,
        'limit': ?limit,
      },
    );
    return ((json['commits'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => HvMindCommit.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// `GET /api/mind/diff?from=&to=&memory_id=&branch=` — single-memory diff
  /// between two refs (commit ids, branch names, or timestamps).
  Future<HvMemoryDiffResult> diffMemory({
    required String from,
    required String to,
    required String memoryId,
    String? branch,
  }) async {
    final json = await _client.get(
      '/api/mind/diff',
      query: {
        'from': from,
        'to': to,
        'memory_id': memoryId,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
      },
    );
    // memory_id isn't echoed at the top level for a single-memory diff.
    return HvMemoryDiffResult.fromJson({...json, 'memory_id': memoryId});
  }

  /// `POST /api/mind/merge` — merge `source` into `target` (default `main`).
  /// On a clean merge this resolves with the change counts. On conflict the
  /// server returns 409 with a `conflicts[]` payload that [HyperVaultApiClient]
  /// currently collapses to `{status, error}` — callers only see the error
  /// message (see [HvMergeOutcome] doc comment).
  Future<HvMergeOutcome> merge({
    required String source,
    String target = 'main',
    String? message,
  }) async {
    final json = await _client.post(
      '/api/mind/merge',
      body: {
        'source': source,
        'target': target,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    return HvMergeOutcome.fromJson(json);
  }
}
