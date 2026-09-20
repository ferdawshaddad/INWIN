import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Show a reusable confirmation dialog.
/// Returns true if user confirmed, false/null if cancelled.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  String cancelLabel = 'Annuler',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cancelled,
                  minimumSize: const Size(0, 40),
                )
              : ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
