/// Pure helpers for redeeming a HyperVault invite code, mirroring the web
/// app's `lib/invites.ts` (`normalizeInviteCode` + `REDEEM_MESSAGES`). Kept
/// free of Supabase/Flutter imports so they're trivially unit-testable —
/// see [HyperVaultAuthService.redeemInviteCode] for the RPC call itself.
library;

/// Uppercases and trims a user-entered invite code, matching the format the
/// server compares against (`upper(trim(p_code))`, migration
/// `0011_invite_gate.sql`).
String normalizeInviteCode(String raw) => raw.trim().toUpperCase();

/// Friendly copy for each non-success `redeem_invite_code()` result,
/// mirroring the web app's `REDEEM_MESSAGES`. `ok` and `already_approved`
/// aren't included — callers treat those as success, not an error to show.
const Map<String, String> hvRedeemMessages = {
  'invalid': "That invite code doesn't exist — double-check for typos.",
  'disabled': 'That invite code has been deactivated.',
  'exhausted': 'That invite code has already been used up.',
  'not_authenticated': 'Sign in first, then enter your invite code.',
};

/// Whether a `redeem_invite_code()` result means the account is now
/// unlocked.
bool hvRedeemResultIsSuccess(String result) =>
    result == 'ok' || result == 'already_approved';
