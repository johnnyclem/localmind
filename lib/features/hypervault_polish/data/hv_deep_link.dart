/// Pure parsing of HyperVault deep links / universal links into a typed
/// description of the screen + params a `hypervault://` or `https://<app
/// domain>` URL resolves to. See docs/mobile/prd/16-cross-cutting.md
/// T-M16-03 and the engineering spec §9 for the param list.
///
/// This is intentionally navigation-free: it only classifies a [Uri]. A
/// follow-up wires [parseHyperVaultDeepLink] into go_router's `redirect` (or
/// an app-links listener) to actually push a route. Host validation against
/// the connected deployment's canonical `app_url` (from capabilities) is
/// also left to that follow-up — this parser accepts any http(s) host so it
/// keeps working for self-hosted deployments, and the custom `hypervault://`
/// scheme regardless of "host" segment.
library;

/// One resolved deep link target. Compare with a switch expression (the
/// class is sealed, so the analyzer flags a missing case).
sealed class HvDeepLink {
  const HvDeepLink();
}

/// `/a/<slug>` — open a vault artifact.
class HvOpenArtifactDeepLink extends HvDeepLink {
  final String slug;
  const HvOpenArtifactDeepLink(this.slug);

  @override
  bool operator ==(Object other) =>
      other is HvOpenArtifactDeepLink && other.slug == slug;
  @override
  int get hashCode => Object.hash(HvOpenArtifactDeepLink, slug);
  @override
  String toString() => 'HvOpenArtifactDeepLink($slug)';
}

/// `/c/<slug>` — open a shared conversation.
class HvOpenConversationDeepLink extends HvDeepLink {
  final String slug;
  const HvOpenConversationDeepLink(this.slug);

  @override
  bool operator ==(Object other) =>
      other is HvOpenConversationDeepLink && other.slug == slug;
  @override
  int get hashCode => Object.hash(HvOpenConversationDeepLink, slug);
  @override
  String toString() => 'HvOpenConversationDeepLink($slug)';
}

/// `?open=<id>` — open an arbitrary item by id (vault/memory item, per the
/// web app's generic `open` param). [path] carries whatever base path the
/// param rode in on (e.g. `/` or `/vault`) so the follow-up router can
/// disambiguate item kind if the id alone is ambiguous.
class HvOpenItemDeepLink extends HvDeepLink {
  final String id;
  final String path;
  const HvOpenItemDeepLink(this.id, {this.path = '/'});

  @override
  bool operator ==(Object other) =>
      other is HvOpenItemDeepLink && other.id == id && other.path == path;
  @override
  int get hashCode => Object.hash(HvOpenItemDeepLink, id, path);
  @override
  String toString() => 'HvOpenItemDeepLink($id, path: $path)';
}

/// `?source_prompt=<text>` — prefill "New from chat" (M3) with the given
/// prompt text, optionally scoped to a target [path] (defaults to the vault
/// create flow).
class HvNewFromChatDeepLink extends HvDeepLink {
  final String sourcePrompt;
  const HvNewFromChatDeepLink(this.sourcePrompt);

  @override
  bool operator ==(Object other) =>
      other is HvNewFromChatDeepLink && other.sourcePrompt == sourcePrompt;
  @override
  int get hashCode => Object.hash(HvNewFromChatDeepLink, sourcePrompt);
  @override
  String toString() => 'HvNewFromChatDeepLink($sourcePrompt)';
}

/// `?branch=<name>` — open the git-mind branch view (M7) on a given branch,
/// optionally scoped to a memory [memoryId] if the link also carried one.
class HvBranchDeepLink extends HvDeepLink {
  final String branch;
  final String? memoryId;
  const HvBranchDeepLink(this.branch, {this.memoryId});

  @override
  bool operator ==(Object other) =>
      other is HvBranchDeepLink &&
      other.branch == branch &&
      other.memoryId == memoryId;
  @override
  int get hashCode => Object.hash(HvBranchDeepLink, branch, memoryId);
  @override
  String toString() => 'HvBranchDeepLink($branch, memoryId: $memoryId)';
}

/// `?invite=<code|1>` — redeem-invite / waitlist flow (M2). `invite=1` with
/// no code means "show the redeem screen"; a non-"1" value is treated as the
/// invite code itself.
class HvInviteDeepLink extends HvDeepLink {
  final String? code;
  const HvInviteDeepLink({this.code});

  @override
  bool operator ==(Object other) =>
      other is HvInviteDeepLink && other.code == code;
  @override
  int get hashCode => Object.hash(HvInviteDeepLink, code);
  @override
  String toString() => 'HvInviteDeepLink(code: $code)';
}

/// A path/param combination that isn't a HyperVault deep link this app
/// understands. Carries the original [uri] and, if present, a `?next=`
/// param so an auth-gated caller can resume after sign-in even when the rest
/// of the link is unrecognized.
class HvUnknownDeepLink extends HvDeepLink {
  final Uri uri;
  const HvUnknownDeepLink(this.uri);

  @override
  bool operator ==(Object other) => other is HvUnknownDeepLink && other.uri == uri;
  @override
  int get hashCode => Object.hash(HvUnknownDeepLink, uri);
  @override
  String toString() => 'HvUnknownDeepLink($uri)';
}

/// `?next=<path>` extracted alongside any of the above, for post-auth resume
/// (spec §9 / T-M16-03). Read off [HvDeepLink]s that carry it via
/// [hvDeepLinkNextParam]; kept out of the sealed hierarchy itself since
/// `next` composes with every other link kind rather than being one.
String? hvDeepLinkNextParam(Uri uri) {
  final next = uri.queryParameters['next'];
  return (next == null || next.isEmpty) ? null : next;
}

/// Auth-provider callback paths (`hypervault://auth/callback`,
/// `/auth/callback`, `/auth/mobile`) are Supabase's job
/// ([HyperVaultAuthService]/`app_links`), not this router-facing parser's —
/// recognized here only so callers can cheaply skip them instead of routing
/// to [HvUnknownDeepLink].
bool isHvAuthCallbackDeepLink(Uri uri) {
  final segments = _pathSegments(uri);
  if (uri.scheme == 'hypervault' && uri.host == 'auth') return true;
  if (segments.isNotEmpty && segments.first == 'auth') return true;
  return false;
}

List<String> _pathSegments(Uri uri) {
  final segments = <String>[];
  // Custom-scheme links parse the authority as `host`, e.g.
  // hypervault://a/<slug> -> host="a", path="/<slug>" — fold it back in as
  // the first segment. Universal links (http/https) never need this: their
  // host is the domain, and the meaningful segments are already in `path`.
  if (uri.scheme == 'hypervault' && uri.host.isNotEmpty) {
    segments.add(uri.host);
  }
  segments.addAll(uri.pathSegments.where((s) => s.isNotEmpty));
  return segments;
}

/// Classifies a `hypervault://…` or `https://…` [Uri] into an [HvDeepLink].
/// Returns null for auth-callback URLs (see [isHvAuthCallbackDeepLink]) and
/// for URIs that carry neither a recognized path nor a recognized query
/// param — those should fall through to [HvUnknownDeepLink] only when the
/// caller wants to still resolve `?next=`; call that helper directly if so.
HvDeepLink? parseHyperVaultDeepLink(Uri uri) {
  if (uri.scheme != 'hypervault' && uri.scheme != 'http' && uri.scheme != 'https') {
    return null;
  }
  if (isHvAuthCallbackDeepLink(uri)) return null;

  final segments = _pathSegments(uri);
  final query = uri.queryParameters;

  // Path-based targets take priority over query params when both are
  // present (e.g. a share link that also carries `?next=`).
  if (segments.length >= 2 && segments[0] == 'a' && segments[1].isNotEmpty) {
    return HvOpenArtifactDeepLink(segments[1]);
  }
  if (segments.length >= 2 && segments[0] == 'c' && segments[1].isNotEmpty) {
    return HvOpenConversationDeepLink(segments[1]);
  }

  final sourcePrompt = query['source_prompt'];
  if (sourcePrompt != null && sourcePrompt.isNotEmpty) {
    return HvNewFromChatDeepLink(sourcePrompt);
  }

  final branch = query['branch'];
  if (branch != null && branch.isNotEmpty) {
    return HvBranchDeepLink(branch, memoryId: query['memory_id']);
  }

  final invite = query['invite'];
  if (invite != null && invite.isNotEmpty) {
    return HvInviteDeepLink(code: invite == '1' ? null : invite);
  }

  final open = query['open'];
  if (open != null && open.isNotEmpty) {
    final path = '/${segments.join('/')}';
    return HvOpenItemDeepLink(open, path: path.isEmpty ? '/' : path);
  }

  return HvUnknownDeepLink(uri);
}
