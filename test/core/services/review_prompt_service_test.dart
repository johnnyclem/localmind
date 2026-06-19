import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/core/services/review_prompt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const version = '1.2.3+4';
  final now = DateTime(2026, 1, 1, 12);

  Future<_Fixture> createFixture({
    Map<String, Object> initialValues = const {},
    bool available = true,
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final prefs = await SharedPreferences.getInstance();
    final client = _FakeReviewPromptClient(available: available);
    final service = ReviewPromptService(
      prefs: prefs,
      client: client,
      appVersionLoader: () async => version,
      now: () => now,
      cooldown: const Duration(days: 30),
    );
    return _Fixture(service: service, client: client, prefs: prefs);
  }

  group('ReviewPromptService', () {
    test(
      'requests review after the third substantial chat completion',
      () async {
        final fixture = await createFixture();

        expect(
          await fixture.service.maybeRequestReviewAfterSuccessfulChat(
            assistantContent: _content(),
            serverType: ServerType.ollama,
          ),
          false,
        );
        expect(
          await fixture.service.maybeRequestReviewAfterSuccessfulChat(
            assistantContent: _content(),
            serverType: ServerType.ollama,
          ),
          false,
        );
        expect(fixture.client.requestCount, 0);

        expect(
          await fixture.service.maybeRequestReviewAfterSuccessfulChat(
            assistantContent: _content(),
            serverType: ServerType.ollama,
          ),
          true,
        );

        expect(fixture.client.requestCount, 1);
        expect(
          fixture.prefs.getInt(ReviewPromptService.successfulChatCountKey),
          3,
        );
        expect(
          fixture.prefs.getString(ReviewPromptService.lastRequestedVersionKey),
          version,
        );
      },
    );

    test('ignores short assistant responses', () async {
      final fixture = await createFixture();

      expect(
        await fixture.service.maybeRequestReviewAfterSuccessfulChat(
          assistantContent: 'Too short.',
          serverType: ServerType.ollama,
        ),
        false,
      );

      expect(fixture.client.requestCount, 0);
      expect(
        fixture.prefs.getInt(ReviewPromptService.successfulChatCountKey),
        null,
      );
    });

    test('does not request review during cooldown', () async {
      final fixture = await createFixture(
        initialValues: {
          ReviewPromptService.successfulChatCountKey: 2,
          ReviewPromptService.lastRequestedVersionKey: '1.2.2+3',
          ReviewPromptService.lastRequestMillisKey: now
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
        },
      );

      expect(
        await fixture.service.maybeRequestReviewAfterSuccessfulChat(
          assistantContent: _content(),
          serverType: ServerType.ollama,
        ),
        false,
      );

      expect(fixture.client.requestCount, 0);
    });

    test('does not request more than once per app version', () async {
      final fixture = await createFixture(
        initialValues: {
          ReviewPromptService.successfulChatCountKey: 2,
          ReviewPromptService.lastRequestedVersionKey: version,
          ReviewPromptService.lastRequestMillisKey: now
              .subtract(const Duration(days: 60))
              .millisecondsSinceEpoch,
        },
      );

      expect(
        await fixture.service.maybeRequestReviewAfterSuccessfulChat(
          assistantContent: _content(),
          serverType: ServerType.ollama,
        ),
        false,
      );

      expect(fixture.client.requestCount, 0);
    });

    test(
      'requests after a loaded on-device model produces a response',
      () async {
        final fixture = await createFixture();

        await fixture.service.markOnDeviceModelLoaded('gemma-3n');

        expect(
          await fixture.service.maybeRequestReviewAfterSuccessfulChat(
            assistantContent: _content(),
            serverType: ServerType.onDevice,
            modelId: 'other-model',
          ),
          false,
        );

        expect(
          await fixture.service.maybeRequestReviewAfterSuccessfulChat(
            assistantContent: _content(),
            serverType: ServerType.onDevice,
            modelId: 'gemma-3n',
          ),
          true,
        );

        expect(fixture.client.requestCount, 1);
        expect(
          fixture.prefs.getString(
            ReviewPromptService.pendingLoadedOnDeviceModelIdKey,
          ),
          null,
        );
      },
    );

    test(
      'download completion waits until the model is loaded and used',
      () async {
        final fixture = await createFixture();

        await fixture.service.markModelDownloadCompleted('qwen-3');
        expect(
          await fixture.service.maybeRequestReviewAfterSuccessfulChat(
            assistantContent: _content(),
            serverType: ServerType.onDevice,
            modelId: 'qwen-3',
          ),
          false,
        );

        await fixture.service.markOnDeviceModelLoaded('qwen-3');
        expect(
          await fixture.service.maybeRequestReviewAfterSuccessfulChat(
            assistantContent: _content(),
            serverType: ServerType.onDevice,
            modelId: 'qwen-3',
          ),
          true,
        );

        expect(fixture.client.requestCount, 1);
        expect(
          fixture.prefs.getString(
            ReviewPromptService.pendingDownloadedAndLoadedModelIdKey,
          ),
          null,
        );
        expect(
          fixture.prefs.getStringList(
            ReviewPromptService.downloadedModelIdsKey,
          ),
          isEmpty,
        );
      },
    );

    test('requests after a custom persona is used successfully', () async {
      final fixture = await createFixture();

      expect(
        await fixture.service.maybeRequestReviewAfterSuccessfulChat(
          assistantContent: _content(),
          serverType: ServerType.ollama,
          usedCustomPersona: true,
        ),
        true,
      );

      expect(fixture.client.requestCount, 1);
    });
  });
}

String _content() => List.filled(100, 'a').join();

class _Fixture {
  const _Fixture({
    required this.service,
    required this.client,
    required this.prefs,
  });

  final ReviewPromptService service;
  final _FakeReviewPromptClient client;
  final SharedPreferences prefs;
}

class _FakeReviewPromptClient implements ReviewPromptClient {
  _FakeReviewPromptClient({required this.available});

  final bool available;
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requestCount++;
  }
}
