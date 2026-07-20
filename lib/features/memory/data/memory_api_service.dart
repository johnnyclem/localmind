import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/network/hypervault_client.dart';
import 'models/memory.dart';

/// Thin typed wrapper around [HyperVaultClient] for the Memory Wiki
/// endpoints (mobile PRD M6). Mirrors the shape of
/// `lib/features/vault/data/vault_api_service.dart`. Every call threads the
/// active git-mind `branch`; v1 always operates on `'main'` (branch
/// switching UI is out of scope — see M7).
class MemoryApiService {
  final HyperVaultClient _client;

  MemoryApiService(this._client);

  /// `GET /api/memories?branch=` — newest-first, server-capped at 200 rows.
  Future<List<MemoryListItem>> browse({String branch = 'main'}) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/memories',
      query: {'branch': branch},
    );
    final items = (json['memories'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(MemoryListItem.fromJson)
        .toList();
  }

  /// `GET /api/memories?q=&branch=` — hybrid (semantic + keyword) or
  /// lexical-only recall, depending on server config.
  Future<MemorySearchResponse> search(
    String query, {
    String branch = 'main',
  }) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/memories',
      query: {'q': query, 'branch': branch},
    );
    return MemorySearchResponse.fromJson(json);
  }

  /// `GET /api/memories/[id]?branch=`.
  Future<MemoryDetail> fetchDetail(String id, {String branch = 'main'}) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/memories/${Uri.encodeComponent(id)}',
      query: {'branch': branch},
    );
    return MemoryDetail.fromJson(json);
  }

  /// `POST /api/memories`. [content] should already have been checked
  /// against `capabilities.limits.memoryBytes` by the caller.
  Future<SaveMemoryResult> create({
    required String content,
    String? title,
    List<String>? tags,
    String? source,
    String branch = 'main',
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'branch': branch,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (source != null && source.trim().isNotEmpty) 'source': source.trim(),
    };
    final json = await _client.post<Map<String, dynamic>>(
      '/api/memories',
      data: body,
    );
    return SaveMemoryResult.fromJson(json);
  }

  /// `PATCH /api/memories/[id]` — send only changed fields. Throws a 400
  /// `HyperVaultApiException` ("Nothing to change...") if nothing differs.
  Future<SaveMemoryResult> update(
    String id, {
    String? title,
    String? content,
    List<String>? tags,
    String branch = 'main',
  }) async {
    final body = <String, dynamic>{
      'branch': branch,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
    };
    final json = await _client.patch<Map<String, dynamic>>(
      '/api/memories/${Uri.encodeComponent(id)}',
      data: body,
    );
    return SaveMemoryResult.fromJson(json);
  }

  /// `DELETE /api/memories/[id]?branch=`.
  Future<void> delete(String id, {String branch = 'main'}) async {
    await _client.delete<Map<String, dynamic>>(
      '/api/memories/${Uri.encodeComponent(id)}',
      query: {'branch': branch},
    );
  }

  /// `POST /api/memories/import?branch=` with JSON `{ url }` — GitHub repo
  /// URL becomes a project digest, any other URL becomes a scraped
  /// knowledgebase entry.
  Future<SaveMemoryResult> importUrl(
    String url, {
    String branch = 'main',
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/api/memories/import',
      query: {'branch': branch},
      data: {'url': url},
    );
    return SaveMemoryResult.fromJson(json);
  }

  /// `POST /api/memories/import?branch=` multipart `file` field
  /// (PDF/DOCX/md/txt). [bytes] should already have been checked against
  /// `capabilities.limits.importBytes` by the caller.
  ///
  /// Uses [HyperVaultClient.dio] directly (bypassing the JSON-only
  /// get/post/patch/delete helpers) since multipart bodies need
  /// [FormData]; error normalization is duplicated here to match
  /// [HyperVaultClient]'s `{error}` handling so callers can catch
  /// [HyperVaultApiException] uniformly regardless of which path produced
  /// it.
  Future<SaveMemoryResult> importFile({
    required Uint8List bytes,
    required String filename,
    String branch = 'main',
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    late final Response<dynamic> response;
    try {
      response = await _client.dio.request<dynamic>(
        '/api/memories/import',
        data: formData,
        queryParameters: {'branch': branch},
        options: Options(method: 'POST'),
      );
    } on DioException catch (e) {
      throw HyperVaultApiException(
        message: e.message ?? 'Network error contacting HyperVault.',
      );
    }

    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return SaveMemoryResult.fromJson(response.data as Map<String, dynamic>);
    }
    throw _errorFor(status, response.data);
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
