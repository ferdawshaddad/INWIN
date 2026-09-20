import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Full-screen loading overlay. Wrap your Scaffold body with this.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: AppColors.navyBlue, strokeWidth: 3),
                  if (message != null) ...[
                    const SizedBox(height: 14),
                    Text(message!, style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ]),
              ),
            ),
          ),
      ],
    );
  }
}
