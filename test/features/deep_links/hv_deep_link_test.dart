import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/deep_links/data/hv_deep_link.dart';

void main() {
  group('parseHyperVaultDeepLink — artifact links', () {
    test('custom scheme /a/<slug>', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('hypervault://a/my-cool-app'),
      );
      expect(result, const HvOpenArtifactDeepLink('my-cool-app'));
    });

    test('universal link /a/<slug>', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('https://hypervault.store/a/my-cool-app'),
      );
      expect(result, const HvOpenArtifactDeepLink('my-cool-app'));
    });

    test('self-hosted domain still resolves /a/<slug>', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('https://my-hv.example.com/a/other-slug'),
      );
      expect(result, const HvOpenArtifactDeepLink('other-slug'));
    });
  });

  group('parseHyperVaultDeepLink — conversation links', () {
    test('custom scheme /c/<slug>', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('hypervault://c/shared-thread'),
      );
      expect(result, const HvOpenConversationDeepLink('shared-thread'));
    });

    test('universal link /c/<slug>', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('https://hypervault.store/c/shared-thread'),
      );
      expect(result, const HvOpenConversationDeepLink('shared-thread'));
    });
  });

  group('parseHyperVaultDeepLink — query params', () {
    test('?source_prompt= maps to HvNewFromChatDeepLink', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('hypervault://open?source_prompt=build+me+a+timer'),
      );
      expect(result, isA<HvNewFromChatDeepLink>());
      expect(
        (result as HvNewFromChatDeepLink).sourcePrompt,
        'build me a timer',
      );
    });

    test('?branch= maps to HvBranchDeepLink', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('https://hypervault.store/mind?branch=feature-x'),
      );
      expect(result, isA<HvBranchDeepLink>());
      expect((result as HvBranchDeepLink).branch, 'feature-x');
      expect(result.memoryId, isNull);
    });

    test('?branch= with memory_id carries both', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse(
          'https://hypervault.store/mind?branch=feature-x&memory_id=42',
        ),
      );
      expect(result, isA<HvBranchDeepLink>());
      expect((result as HvBranchDeepLink).memoryId, '42');
    });

    test('?invite=1 maps to HvInviteDeepLink with no code', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('hypervault://open?invite=1'),
      );
      expect(result, const HvInviteDeepLink());
    });

    test('?invite=<code> carries the code', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('https://hypervault.store/?invite=ABC123'),
      );
      expect(result, const HvInviteDeepLink(code: 'ABC123'));
    });

    test('?open=<id> maps to HvOpenItemDeepLink with its path', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('https://hypervault.store/vault?open=item-9'),
      );
      expect(result, isA<HvOpenItemDeepLink>());
      final link = result as HvOpenItemDeepLink;
      expect(link.id, 'item-9');
      expect(link.path, '/vault');
    });

    test('path targets win over query params when both are present', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('https://hypervault.store/a/slug-1?next=/settings'),
      );
      expect(result, const HvOpenArtifactDeepLink('slug-1'));
    });
  });

  group('parseHyperVaultDeepLink — auth callback + unknown', () {
    test('custom-scheme auth callback returns null', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('hypervault://auth/callback?code=abc'),
      );
      expect(result, isNull);
    });

    test('universal auth callback path returns null', () {
      final result = parseHyperVaultDeepLink(
        Uri.parse('https://hypervault.store/auth/mobile?code=abc'),
      );
      expect(result, isNull);
    });

    test('unsupported scheme returns null', () {
      final result = parseHyperVaultDeepLink(Uri.parse('mailto:a@b.com'));
      expect(result, isNull);
    });

    test('unrecognized path/params falls back to HvUnknownDeepLink', () {
      final uri = Uri.parse('https://hypervault.store/settings/billing');
      final result = parseHyperVaultDeepLink(uri);
      expect(result, HvUnknownDeepLink(uri));
    });
  });

  group('hvDeepLinkNextParam', () {
    test('extracts ?next= when present', () {
      final uri = Uri.parse(
        'https://hypervault.store/a/slug-1?next=/vault/slug-1',
      );
      expect(hvDeepLinkNextParam(uri), '/vault/slug-1');
    });

    test('returns null when absent', () {
      final uri = Uri.parse('https://hypervault.store/a/slug-1');
      expect(hvDeepLinkNextParam(uri), isNull);
    });

    test('returns null for an empty value', () {
      final uri = Uri.parse('https://hypervault.store/a/slug-1?next=');
      expect(hvDeepLinkNextParam(uri), isNull);
    });
  });

  group('isHvAuthCallbackDeepLink', () {
    test('true for hypervault://auth/*', () {
      expect(
        isHvAuthCallbackDeepLink(Uri.parse('hypervault://auth/callback')),
        isTrue,
      );
    });

    test('true for /auth/* universal paths', () {
      expect(
        isHvAuthCallbackDeepLink(
          Uri.parse('https://hypervault.store/auth/callback'),
        ),
        isTrue,
      );
    });

    test('false for unrelated paths', () {
      expect(
        isHvAuthCallbackDeepLink(Uri.parse('https://hypervault.store/a/x')),
        isFalse,
      );
    });
  });

  group('isMcpOAuthCallbackDeepLink', () {
    test('true for hypervault://mcp-oauth-callback', () {
      expect(
        isMcpOAuthCallbackDeepLink(
          Uri.parse('hypervault://mcp-oauth-callback?code=abc&state=xyz'),
        ),
        isTrue,
      );
    });

    test('false for the unrelated auth callback host', () {
      expect(
        isMcpOAuthCallbackDeepLink(Uri.parse('hypervault://auth/callback')),
        isFalse,
      );
    });

    test('false for a universal-link URL, even with a matching path', () {
      expect(
        isMcpOAuthCallbackDeepLink(
          Uri.parse('https://hypervault.store/mcp-oauth-callback'),
        ),
        isFalse,
      );
    });
  });
}
