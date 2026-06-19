import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';

abstract class ReviewPromptClient {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class InAppReviewPromptClient implements ReviewPromptClient {
  InAppReviewPromptClient({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<bool> isAvailable() => _inAppReview.isAvailable();

  @override
  Future<void> requestReview() => _inAppReview.requestReview();
}

class ReviewPromptService {
  ReviewPromptService({
    required this.prefs,
    required this.client,
    required this.appVersionLoader,
    DateTime Function()? now,
    this.cooldown = const Duration(days: 30),
    this.successfulChatThreshold = 3,
    this.minSubstantialResponseLength = 80,
  }) : clock = now ?? DateTime.now;

  static const successfulChatCountKey = 'reviewPrompt.successfulChatCount';
  static const lastRequestMillisKey = 'reviewPrompt.lastRequestMillis';
  static const lastRequestedVersionKey = 'reviewPrompt.lastRequestedVersion';
  static const pendingLoadedOnDeviceModelIdKey =
      'reviewPrompt.pendingLoadedOnDeviceModelId';
  static const downloadedModelIdsKey = 'reviewPrompt.downloadedModelIds';
  static const pendingDownloadedAndLoadedModelIdKey =
      'reviewPrompt.pendingDownloadedAndLoadedModelId';

  final SharedPreferences prefs;
  final ReviewPromptClient client;
  final Future<String> Function() appVersionLoader;
  final DateTime Function() clock;
  final Duration cooldown;
  final int successfulChatThreshold;
  final int minSubstantialResponseLength;

  bool _requestInFlight = false;

  Future<void> markModelDownloadCompleted(String modelId) async {
    final downloadedIds = prefs.getStringList(downloadedModelIdsKey) ?? [];
    if (!downloadedIds.contains(modelId)) {
      await prefs.setStringList(downloadedModelIdsKey, [
        ...downloadedIds,
        modelId,
      ]);
    }
  }

  Future<void> markOnDeviceModelLoaded(String modelId) async {
    await prefs.setString(pendingLoadedOnDeviceModelIdKey, modelId);

    final downloadedIds = prefs.getStringList(downloadedModelIdsKey) ?? [];
    if (downloadedIds.contains(modelId)) {
      await prefs.setString(pendingDownloadedAndLoadedModelIdKey, modelId);
    }
  }

  Future<bool> maybeRequestReviewAfterSuccessfulChat({
    required String assistantContent,
    required ServerType serverType,
    String? modelId,
    bool usedCustomPersona = false,
  }) async {
    if (assistantContent.trim().length < minSubstantialResponseLength) {
      return false;
    }

    final successfulChatCount = (prefs.getInt(successfulChatCountKey) ?? 0) + 1;
    await prefs.setInt(successfulChatCountKey, successfulChatCount);

    final matchedLoadedOnDeviceModel =
        serverType == ServerType.onDevice &&
        modelId != null &&
        prefs.getString(pendingLoadedOnDeviceModelIdKey) == modelId;

    final matchedDownloadedAndLoadedModel =
        serverType == ServerType.onDevice &&
        modelId != null &&
        prefs.getString(pendingDownloadedAndLoadedModelIdKey) == modelId;

    final hasSpecialPositiveSignal =
        matchedLoadedOnDeviceModel ||
        matchedDownloadedAndLoadedModel ||
        usedCustomPersona;

    if (successfulChatCount < successfulChatThreshold &&
        !hasSpecialPositiveSignal) {
      return false;
    }

    if (!await _canRequestReview()) {
      return false;
    }

    if (_requestInFlight) {
      return false;
    }

    _requestInFlight = true;
    try {
      final available = await client.isAvailable();
      if (!available) {
        return false;
      }

      await client.requestReview();
      await _recordReviewAttempt();
      await _consumeMatchedSignals(
        consumeLoadedOnDevice: matchedLoadedOnDeviceModel,
        consumeDownloadedAndLoaded: matchedDownloadedAndLoadedModel,
      );
      return true;
    } finally {
      _requestInFlight = false;
    }
  }

  Future<bool> _canRequestReview() async {
    final currentVersion = await _currentAppVersion();
    if (prefs.getString(lastRequestedVersionKey) == currentVersion) {
      return false;
    }

    final lastRequestMillis = prefs.getInt(lastRequestMillisKey);
    if (lastRequestMillis == null) {
      return true;
    }

    final lastRequestAt = DateTime.fromMillisecondsSinceEpoch(
      lastRequestMillis,
    );
    return clock().difference(lastRequestAt) >= cooldown;
  }

  Future<void> _recordReviewAttempt() async {
    await prefs.setString(lastRequestedVersionKey, await _currentAppVersion());
    await prefs.setInt(lastRequestMillisKey, clock().millisecondsSinceEpoch);
  }

  Future<void> _consumeMatchedSignals({
    required bool consumeLoadedOnDevice,
    required bool consumeDownloadedAndLoaded,
  }) async {
    if (consumeLoadedOnDevice) {
      await prefs.remove(pendingLoadedOnDeviceModelIdKey);
    }

    if (consumeDownloadedAndLoaded) {
      final modelId = prefs.getString(pendingDownloadedAndLoadedModelIdKey);
      await prefs.remove(pendingDownloadedAndLoadedModelIdKey);

      if (modelId != null) {
        final downloadedIds = prefs.getStringList(downloadedModelIdsKey) ?? [];
        await prefs.setStringList(
          downloadedModelIdsKey,
          downloadedIds.where((id) => id != modelId).toList(),
        );
      }
    }
  }

  Future<String> _currentAppVersion() async {
    try {
      return await appVersionLoader();
    } catch (_) {
      return 'unknown';
    }
  }
}
