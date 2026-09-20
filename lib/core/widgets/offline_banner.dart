import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../services/connectivity_service.dart';

/// Drop this anywhere in the widget tree (typically just above the body
/// content inside a Column) to show/hide an offline warning automatically.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isOnline
          ? const SizedBox.shrink()
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              color: AppColors.cancelled,
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 15),
                  SizedBox(width: 8),
                  Text(
                    'Pas de connexion — certaines fonctions sont indisponibles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
