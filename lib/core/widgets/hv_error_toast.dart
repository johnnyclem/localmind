import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../network/hypervault_api_exception.dart';

/// Shows a friendly toast for any error a HyperVault call can throw,
/// pattern-matching [HyperVaultApiException] into distinct copy (waitlisted,
/// rate limited, service unavailable, unauthorized) and falling back to the
/// raw error/exception message otherwise. Every HyperVault screen should
/// call this instead of hand-rolling its own
/// `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...)))`
/// for API errors, so failure copy stays consistent app-wide.
///
/// [HyperVaultApiException] has no dedicated "waitlisted" status code of its
/// own — the server enforces the invite gate with a plain 403
/// ([HyperVaultApiException.isForbidden]), same as any other forbidden
/// request (see the comment on `AuthGateStatus` in
/// `lib/features/auth/data/models/auth_gate_status.dart`) — so that's the
/// signal used for the waitlist copy below.
void showHvError(BuildContext context, Object error) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final theme = Theme.of(context);
  final copy = _copyFor(error);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: copy.duration,
        backgroundColor: theme.colorScheme.errorContainer.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.35 : 1,
        ),
        content: Semantics(
          liveRegion: true,
          label: '${copy.title}. ${copy.message}',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HugeIcon(icon: copy.icon, color: theme.colorScheme.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      copy.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(copy.message, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

class _HvErrorCopy {
  final String title;
  final String message;
  final dynamic icon;
  final Duration duration;

  const _HvErrorCopy({
    required this.title,
    required this.message,
    required this.icon,
    this.duration = const Duration(seconds: 4),
  });
}

_HvErrorCopy _copyFor(Object error) {
  if (error is HyperVaultApiException) {
    if (error.isForbidden) {
      return const _HvErrorCopy(
        title: "You're on the waitlist",
        message:
            'Redeem an invite code or claim access from the web app, then '
            'try again.',
        icon: HugeIcons.strokeRoundedUserList,
        duration: Duration(seconds: 6),
      );
    }
    if (error.isRateLimited) {
      return const _HvErrorCopy(
        title: 'Slow down a little',
        message: "You've hit HyperVault's rate limit — give it a few "
            'seconds and try again.',
        icon: HugeIcons.strokeRoundedTimer02,
      );
    }
    if (error.isServiceUnavailable) {
      return const _HvErrorCopy(
        title: 'HyperVault is temporarily unavailable',
        message: 'The service is having trouble right now. Your changes '
            "weren't lost — try again shortly.",
        icon: HugeIcons.strokeRoundedCloudServer,
        duration: Duration(seconds: 6),
      );
    }
    if (error.isUnauthorized) {
      return const _HvErrorCopy(
        title: 'Signed out of HyperVault',
        message: 'Your session expired — sign in again to continue.',
        icon: HugeIcons.strokeRoundedLogout03,
        duration: Duration(seconds: 6),
      );
    }
    if (error.isNetworkError) {
      return const _HvErrorCopy(
        title: 'Connection trouble',
        message: 'Could not reach HyperVault. Check your connection and try again.',
        icon: HugeIcons.strokeRoundedWifiDisconnected01,
      );
    }
    return _HvErrorCopy(
      title: 'HyperVault error',
      message: error.message,
      icon: HugeIcons.strokeRoundedAlert02,
    );
  }
  return _HvErrorCopy(
    title: 'Something went wrong',
    message: '$error',
    icon: HugeIcons.strokeRoundedAlert02,
  );
}
