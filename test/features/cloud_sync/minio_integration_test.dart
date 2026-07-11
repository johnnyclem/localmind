import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/cloud_sync/data/models/cloud_sync_models.dart';
import 'package:localmind/features/cloud_sync/data/repositories/s3_cloud_sync_repository.dart';
import 'package:localmind/features/cloud_sync/services/cloud_sync_crypto_service.dart';

void main() {
  final endpoint = Platform.environment['LOCALMIND_MINIO_ENDPOINT'];

  test(
    'two clients exchange encrypted state through MinIO',
    () async {
      final prefix =
          'localmind-integration-${DateTime.now().microsecondsSinceEpoch}';
      final config = S3SyncConfig(
        endpoint: endpoint!,
        bucket: Platform.environment['LOCALMIND_MINIO_BUCKET']!,
        region: Platform.environment['LOCALMIND_MINIO_REGION'] ?? 'us-east-1',
        prefix: prefix,
        pathStyle: true,
        allowInsecureHttp: endpoint.startsWith('http://'),
      );
      final credentials = CloudSyncCredentials(
        accessKeyId: Platform.environment['LOCALMIND_MINIO_ACCESS_KEY']!,
        secretAccessKey: Platform.environment['LOCALMIND_MINIO_SECRET_KEY']!,
      );
      final firstClient = S3CloudSyncRepository(
        config: config,
        credentials: credentials,
      );
      final secondClient = S3CloudSyncRepository(
        config: config,
        credentials: credentials,
      );
      final crypto = CloudSyncCryptoService();
      final salt = crypto.newSalt();
      final key = await crypto.deriveMasterKey('integration-passphrase', salt);
      final encrypted = await crypto.encryptState(
        utf8.encode('{"device":"one"}'),
        masterKey: key,
        salt: salt,
      );

      try {
        await firstClient.testConnection();
        final etag = await firstClient.writeState(encrypted, createOnly: true);
        final downloaded = await secondClient.readState();
        expect(downloaded, isNotNull);
        expect(
          utf8.decode(await crypto.decryptState(downloaded!.bytes, key)),
          '{"device":"one"}',
        );
        await expectLater(
          crypto.decryptState(downloaded.bytes, List<int>.filled(32, 5)),
          throwsA(isA<CloudSyncFailure>()),
        );
        await secondClient.writeState(encrypted, expectedEtag: etag);
      } finally {
        await firstClient.deleteObject(firstClient.stateKey);
      }
    },
    skip:
        endpoint == null ||
            Platform.environment['LOCALMIND_MINIO_BUCKET'] == null ||
            Platform.environment['LOCALMIND_MINIO_ACCESS_KEY'] == null ||
            Platform.environment['LOCALMIND_MINIO_SECRET_KEY'] == null
        ? 'Set LOCALMIND_MINIO_* environment variables to run this test.'
        : false,
  );
}
