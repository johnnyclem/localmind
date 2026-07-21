import 'package:dio/dio.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/network/hypervault_client.dart';
import 'models/git_mind_models.dart';

/// Thrown by [GitMindApiService.merge] on a 409 whose body carries a
/// `conflicts[]` array (rather than a plain `{error}`). Kept distinct from
/// [HyperVaultApiException] since callers need the parsed conflict list, not
/// just a message string.
class MergeConflictException implements Exception {
  final String message;
  final List<MergeConflict> conflicts;

  const MergeConflictException({
    required this.message,
    required this.conflicts,
  });

  @override
  String toString() => message;
}

/// Thin typed wrapper around [HyperVaultClient] for the Git-for-a-Mind
/// endpoints (mobile PRD M7): branches, commits, time-travel state, merge
/// (+conflict resolution), memory history, diff, and revert.
class GitMindApiService {
  final HyperVaultClient _client;

  GitMindApiService(this._client);

  /// `GET /api/mind/branches`.
  Future<List<MindBranch>> fetchBranches() async {
    final json = await _client.get<Map<String, dynamic>>('/api/mind/branches');
    final rows = (json['branches'] as List?) ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MindBranch.fromJson)
        .toList();
  }

  /// `POST /api/mind/branches`.
  Future<CreateBranchResult> createBranch({
    required String name,
    String from = 'main',
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/api/mind/branches',
      data: {'name': name, 'from': from},
    );
    return CreateBranchResult.fromJson(json);
  }

  /// `DELETE /api/mind/branches/[name]`. The 400 (default branch) / 409
  /// (has children) cases surface as [HyperVaultApiException] with the
  /// server's `.message` — callers should show it verbatim.
  Future<String> deleteBranch(String name) async {
    final json = await _client.delete<Map<String, dynamic>>(
      '/api/mind/branches/${Uri.encodeComponent(name)}',
    );
    return json['message'] as String? ?? 'Branch deleted.';
  }

  /// `GET /api/mind/commits?branch=&limit=`.
  Future<CommitLog> fetchCommits({
    required String branch,
    int limit = 30,
  }) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/mind/commits',
      query: {'branch': branch, 'limit': limit},
    );
    return CommitLog.fromJson(json);
  }

  /// `GET /api/mind/state?at=&branch=` — read-only time-travel snapshot.
  /// [at] may be a commit id, a branch name, or an ISO timestamp.
  Future<MindStateSnapshot> fetchState({
    required String at,
    String? branch,
  }) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/mind/state',
      query: {'at': at, if (branch != null) 'branch': branch},
    );
    return MindStateSnapshot.fromJson(json);
  }

  /// `GET /api/memories/[id]/history?limit=&full=1`.
  Future<MemoryHistory> fetchHistory(String memoryId, {int limit = 50}) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/memories/${Uri.encodeComponent(memoryId)}/history',
      query: {'limit': limit, 'full': 1},
    );
    return MemoryHistory.fromJson(json);
  }

  /// `GET /api/mind/diff?from=&to=&memory_id=&branch=`.
  Future<DiffResult> fetchDiff({
    String? from,
    required String to,
    String? memoryId,
    String? branch,
  }) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/mind/diff',
      query: {
        if (from != null) 'from': from,
        'to': to,
        if (memoryId != null) 'memory_id': memoryId,
        if (branch != null) 'branch': branch,
      },
    );
    return DiffResult.fromJson(json);
  }

  /// `POST /api/mind/revert`.
  Future<RevertResult> revert({
    required String memoryId,
    required String revisionId,
    String? branch,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/api/mind/revert',
      data: {
        'memory_id': memoryId,
        'revision_id': revisionId,
        if (branch != null) 'branch': branch,
      },
    );
    return RevertResult.fromJson(json);
  }

  /// `POST /api/mind/merge`. On a clean merge, returns [MergeResult]. On a
  /// 409 conflict response (`{error, conflicts: [...]}`), throws
  /// [MergeConflictException] rather than the generic
  /// [HyperVaultApiException] — [HyperVaultClient]'s own `get`/`post` helpers
  /// normalize every non-2xx response down to `{message, code}` and discard
  /// the rest of the body (see `HyperVaultClient._errorFor`), which would
  /// lose the `conflicts` array. So this call bypasses those helpers and
  /// talks to [HyperVaultClient.dio] directly, replicating just enough of
  /// `_send`'s success/error handling to also special-case a 409 with a
  /// `conflicts` list.
  Future<MergeResult> merge({
    required String source,
    String target = 'main',
    String? message,
    List<MergeResolution>? resolutions,
  }) async {
    final data = <String, dynamic>{
      'source': source,
      'target': target,
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
      if (resolutions != null && resolutions.isNotEmpty)
        'resolutions': resolutions.map((r) => r.toJson()).toList(),
    };

    late final Response<dynamic> response;
    try {
      response = await _client.dio.request<dynamic>(
        '/api/mind/merge',
        data: data,
        options: Options(method: 'POST'),
      );
    } on DioException catch (e) {
      throw HyperVaultApiException(
        message: e.message ?? 'Network error contacting HyperVault.',
      );
    }

    final status = response.statusCode ?? 0;
    final body = response.data;
    if (status >= 200 && status < 300) {
      return MergeResult.fromJson(body as Map<String, dynamic>);
    }

    if (status == 409 &&
        body is Map<String, dynamic> &&
        body['conflicts'] is List) {
      final conflicts = (body['conflicts'] as List)
          .whereType<Map<String, dynamic>>()
          .map(MergeConflict.fromJson)
          .toList();
      throw MergeConflictException(
        message:
            body['error'] as String? ?? 'This merge has conflicts to resolve.',
        conflicts: conflicts,
      );
    }

    throw _errorFor(status, body);
  }

  HyperVaultApiException _errorFor(int status, dynamic body) {
    String message = 'Request failed ($status).';
    String? code;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is String && err.isNotEmpty) message = err;
      final c = body['code'];
      if (c is String) code = c;
    } else if (body is String && body.isNotEmpty) {
      message = body;
    }
    return HyperVaultApiException(
      statusCode: status,
      message: message,
      code: code,
    );
  }
}
