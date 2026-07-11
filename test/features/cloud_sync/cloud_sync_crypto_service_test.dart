import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/cloud_sync/data/models/cloud_sync_models.dart';
import 'package:localmind/features/cloud_sync/services/cloud_sync_crypto_service.dart';

void main() {
  group('CloudSyncCryptoService', () {
    final service = CloudSyncCryptoService();
    final salt = List<int>.generate(16, (index) => index);
    final masterKey = List<int>.generate(32, (index) => index + 1);

    test('round trips authenticated compressed state', () async {
      final clear = utf8.encode('{"private":"chat"}');
      final encrypted = await service.encryptState(
        clear,
        masterKey: masterKey,
        salt: salt,
      );

      expect(utf8.decode(encrypted), isNot(contains('private')));
      expect(service.extractSalt(encrypted), salt);
      expect(await service.decryptState(encrypted, masterKey), clear);
    });

    test('rejects the wrong key without returning plaintext', () async {
      final encrypted = await service.encryptState(
        utf8.encode('secret'),
        masterKey: masterKey,
        salt: salt,
      );

      await expectLater(
        service.decryptState(encrypted, List<int>.filled(32, 9)),
        throwsA(
          isA<CloudSyncFailure>().having(
            (error) => error.kind,
            'kind',
            CloudSyncFailureKind.passphrase,
          ),
        ),
      );
    });

    test('uses deterministic keyed attachment identifiers', () async {
      final first = await service.attachmentIdentifier([1, 2, 3], masterKey);
      final second = await service.attachmentIdentifier([1, 2, 3], masterKey);
      final different = await service.attachmentIdentifier([
        1,
        2,
        4,
      ], masterKey);

      expect(first, second);
      expect(first, isNot(different));
    });

    test(
      'derives a stable 256-bit key and validates passphrase length',
      () async {
        final first = await service.deriveMasterKey('correct horse', salt);
        final second = await service.deriveMasterKey('correct horse', salt);
        expect(first, hasLength(32));
        expect(first, second);
        await expectLater(
          service.deriveMasterKey('short', salt),
          throwsA(isA<CloudSyncFailure>()),
        );
      },
    );
  });
}
