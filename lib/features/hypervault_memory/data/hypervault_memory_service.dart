import '../../hypervault/data/hypervault_api_client.dart';
import 'models/hv_memory_detail.dart';
import 'models/hv_memory_recall_result.dart';
import 'models/hv_memory_revision.dart';
import 'models/hv_memory_summary.dart';
import 'models/hv_memory_write_result.dart';

/// Wraps the memory-wiki endpoints (`/api/memories*`) — browse, recall,
/// memorize, edit, forget, and per-memory history. See
/// docs/mobile/prd/06-memory-wiki.md and api-contract.md `Memory wiki`.
class HypervaultMemoryService {
  final HyperVaultApiClient _client;

  HypervaultMemoryService(this._client);

  /// `GET /api/memories?branch=` — the branch's wiki index, newest first.
  Future<List<HvMemorySummary>> browse({String? branch}) async {
    final json = await _client.get(
      '/api/memories',
      query: {if (branch != null && branch.isNotEmpty) 'branch': branch},
    );
    return ((json['memories'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => HvMemorySummary.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// `GET /api/memories?q=&branch=` — hybrid (main) or lexical (branches)
  /// recall.
  Future<HvMemoryRecallResponse> recall({
    required String query,
    String? branch,
  }) async {
    final json = await _client.get(
      '/api/memories',
      query: {
        'q': query,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
      },
    );
    return HvMemoryRecallResponse.fromJson(json);
  }

  /// `GET /api/memories/[id]?branch=` — one wiki page.
  Future<HvMemoryDetail> getDetail(String id, {String? branch}) async {
    final json = await _client.get(
      '/api/memories/$id',
      query: {if (branch != null && branch.isNotEmpty) 'branch': branch},
    );
    return HvMemoryDetail.fromJson(json);
  }

  /// `POST /api/memories` — memorize a chunk.
  Future<HvMemorizeResult> memorize({
    required String content,
    String? title,
    List<String>? tags,
    String? source,
    String? branch,
    String? message,
  }) async {
    final json = await _client.post(
      '/api/memories',
      body: {
        'content': content,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (source != null && source.isNotEmpty) 'source': source,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    return HvMemorizeResult.fromJson(json);
  }

  /// `PATCH /api/memories/[id]` — edit title/content/tags. Throws
  /// [HvApiError] with status 400 when nothing actually changed.
  Future<HvMemoryEditResult> edit(
    String id, {
    String? title,
    String? content,
    List<String>? tags,
    String? branch,
    String? message,
  }) async {
    final json = await _client.patch(
      '/api/memories/$id',
      body: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (content != null && content.trim().isNotEmpty)
          'content': content.trim(),
        'tags': ?tags,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    return HvMemoryEditResult.fromJson(json);
  }

  /// `DELETE /api/memories/[id]?branch=` — forget. Returns the server's
  /// confirmation message. [HyperVaultApiClient.delete] has no `query`
  /// parameter, so the branch is appended to the path directly.
  Future<String> forget(String id, {String? branch}) async {
    final path = branch != null && branch.isNotEmpty
        ? '/api/memories/$id?branch=${Uri.encodeQueryComponent(branch)}'
        : '/api/memories/$id';
    final json = await _client.delete(path);
    return json['message'] as String? ?? 'Forgotten.';
  }

  /// `GET /api/memories/[id]/history?limit=&full=` — revision timeline.
  Future<List<HvMemoryRevision>> history(
    String id, {
    int? limit,
    bool full = false,
  }) async {
    final json = await _client.get(
      '/api/memories/$id/history',
      query: {'limit': ?limit, if (full) 'full': 1},
    );
    return ((json['revisions'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => HvMemoryRevision.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
