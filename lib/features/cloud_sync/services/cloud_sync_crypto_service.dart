import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart';

import '../data/models/cloud_sync_models.dart';

class CloudSyncCryptoService {
  static const _magic = 'localmind-sync-v1';
  static const _memoryKiB = 32768;
  static const _iterations = 3;
  static const _parallelism = 2;

  final AesGcm _cipher = AesGcm.with256bits();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  List<int> newSalt() => randomBytes(16);

  Future<List<int>> deriveMasterKey(String passphrase, List<int> salt) async {
    if (passphrase.length < 8) {
      throw const CloudSyncFailure(
        CloudSyncFailureKind.validation,
        'The encryption passphrase must be at least 8 characters.',
      );
    }
    final algorithm = Argon2id(
      memory: _memoryKiB,
      parallelism: _parallelism,
      iterations: _iterations,
      hashLength: 32,
    );
    final key = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  Future<SecretKey> _subkey(List<int> masterKey, String purpose) {
    return _hkdf.deriveKey(
      secretKey: SecretKey(masterKey),
      nonce: utf8.encode(_magic),
      info: utf8.encode(purpose),
    );
  }

  Future<List<int>> encryptState(
    List<int> clearText, {
    required List<int> masterKey,
    required List<int> salt,
  }) => _encrypt(clearText, masterKey: masterKey, salt: salt, kind: 'state');

  Future<List<int>> encryptAttachment(
    List<int> clearText, {
    required List<int> masterKey,
    required List<int> salt,
  }) =>
      _encrypt(clearText, masterKey: masterKey, salt: salt, kind: 'attachment');

  Future<List<int>> _encrypt(
    List<int> clearText, {
    required List<int> masterKey,
    required List<int> salt,
    required String kind,
  }) async {
    final header = <String, dynamic>{
      'magic': _magic,
      'version': 1,
      'kind': kind,
      'compression': 'gzip',
      'salt': base64Encode(salt),
      'argon2': {
        'memory': _memoryKiB,
        'iterations': _iterations,
        'parallelism': _parallelism,
      },
    };
    final aad = utf8.encode(jsonEncode(header));
    final box = await _cipher.encrypt(
      gzip.encode(clearText),
      secretKey: await _subkey(masterKey, kind),
      aad: aad,
    );
    return utf8.encode(
      jsonEncode({
        ...header,
        'nonce': base64Encode(box.nonce),
        'ciphertext': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      }),
    );
  }

  Future<List<int>> decryptState(List<int> envelope, List<int> masterKey) =>
      _decrypt(envelope, masterKey: masterKey, expectedKind: 'state');

  Future<List<int>> decryptAttachment(
    List<int> envelope,
    List<int> masterKey,
  ) => _decrypt(envelope, masterKey: masterKey, expectedKind: 'attachment');

  Future<List<int>> _decrypt(
    List<int> envelope, {
    required List<int> masterKey,
    required String expectedKind,
  }) async {
    try {
      final decoded = jsonDecode(utf8.decode(envelope));
      if (decoded is! Map ||
          decoded['magic'] != _magic ||
          decoded['version'] != 1 ||
          decoded['kind'] != expectedKind) {
        throw const FormatException('Unsupported encrypted payload');
      }
      final map = Map<String, dynamic>.from(decoded);
      final header = <String, dynamic>{
        'magic': map['magic'],
        'version': map['version'],
        'kind': map['kind'],
        'compression': map['compression'],
        'salt': map['salt'],
        'argon2': map['argon2'],
      };
      final box = SecretBox(
        base64Decode(map['ciphertext'] as String),
        nonce: base64Decode(map['nonce'] as String),
        mac: Mac(base64Decode(map['mac'] as String)),
      );
      final compressed = await _cipher.decrypt(
        box,
        secretKey: await _subkey(masterKey, expectedKind),
        aad: utf8.encode(jsonEncode(header)),
      );
      return gzip.decode(compressed);
    } on CloudSyncFailure {
      rethrow;
    } catch (_) {
      throw const CloudSyncFailure(
        CloudSyncFailureKind.passphrase,
        'The passphrase is incorrect or the encrypted data was modified.',
      );
    }
  }

  List<int> extractSalt(List<int> envelope) {
    try {
      final decoded = jsonDecode(utf8.decode(envelope)) as Map<String, dynamic>;
      if (decoded['magic'] != _magic || decoded['version'] != 1) {
        throw const FormatException();
      }
      return base64Decode(decoded['salt'] as String);
    } catch (_) {
      throw const CloudSyncFailure(
        CloudSyncFailureKind.corruptedData,
        'The remote sync data has an unsupported or corrupted header.',
      );
    }
  }

  Future<String> attachmentIdentifier(
    List<int> clearText,
    List<int> masterKey,
  ) async {
    final mac = await Hmac.sha256().calculateMac(
      clearText,
      secretKey: await _subkey(masterKey, 'attachment-id'),
    );
    return base64UrlEncode(mac.bytes).replaceAll('=', '');
  }
}
