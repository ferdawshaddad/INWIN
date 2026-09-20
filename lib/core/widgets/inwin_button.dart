import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

enum ButtonVariant { primary, secondary, ghost }

class InwinButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final ButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final double? width;
  final Color? color;

  const InwinButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = ButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
          );

    switch (variant) {
      case ButtonVariant.primary:
        return SizedBox(
          width: width ?? double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onTap,
            style: color != null ? ElevatedButton.styleFrom(backgroundColor: color) : null,
            child: child,
          ),
        );
      case ButtonVariant.secondary:
        return SizedBox(
          width: width ?? double.infinity,
          child: OutlinedButton(onPressed: loading ? null : onTap, child: child),
        );
      case ButtonVariant.ghost:
        return TextButton(
          onPressed: loading ? null : onTap,
          style: TextButton.styleFrom(foregroundColor: AppColors.navyBlue),
          child: child,
        );
    }
  }
}
