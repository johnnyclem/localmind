import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../core/theme/colors.dart';
import 'bootstrap_state.dart';

class BootstrapScreen extends StatelessWidget {
  final BootstrapState state;
  final VoidCallback? onRetry;

  const BootstrapScreen({super.key, required this.state, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo.webp',
                      width: 72,
                      height: 72,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'LocalMind',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (state.stage != BootstrapStage.error) ...[
                    LoadingAnimationWidget.fourRotatingDots(
                      size: 32,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      state.statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkMutedText
                            : AppColors.lightMutedText,
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.error_outline, size: 40, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error?.toString() ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkMutedText
                            : AppColors.lightMutedText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (onRetry != null)
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
