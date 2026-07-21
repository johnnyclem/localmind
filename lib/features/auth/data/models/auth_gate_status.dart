/// Client-side mirror of the server's invite/waitlist gate (T-M2-06). This is
/// advisory only — the server re-checks `account_access` on every request
/// regardless of what the client believes (403 if waitlisted).
enum AuthGateStatus { loading, unauthenticated, waitlisted, approved }
