import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/hypervault/data/hv_invite_redeem.dart';

void main() {
  group('normalizeInviteCode', () {
    test('uppercases and trims', () {
      expect(normalizeInviteCode(' hv-abcd-1234 '), 'HV-ABCD-1234');
    });

    test('already-normalized code is unchanged', () {
      expect(normalizeInviteCode('HV-ABCD-1234'), 'HV-ABCD-1234');
    });
  });

  group('hvRedeemResultIsSuccess', () {
    test('ok and already_approved are success', () {
      expect(hvRedeemResultIsSuccess('ok'), isTrue);
      expect(hvRedeemResultIsSuccess('already_approved'), isTrue);
    });

    test('invalid, disabled, exhausted, not_authenticated are not success', () {
      for (final result in [
        'invalid',
        'disabled',
        'exhausted',
        'not_authenticated',
      ]) {
        expect(hvRedeemResultIsSuccess(result), isFalse, reason: result);
      }
    });
  });

  group('hvRedeemMessages', () {
    test('covers every non-success result code', () {
      for (final result in [
        'invalid',
        'disabled',
        'exhausted',
        'not_authenticated',
      ]) {
        expect(hvRedeemMessages[result], isNotNull, reason: result);
      }
    });

    test('does not map the success codes', () {
      expect(hvRedeemMessages['ok'], isNull);
      expect(hvRedeemMessages['already_approved'], isNull);
    });
  });
}
