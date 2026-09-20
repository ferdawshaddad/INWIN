import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/quote_request.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/request_service.dart';

/// Shows the count of quoted (action-needed) requests on the bell icon.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    final requestsAsync = user == null
        ? const AsyncValue.data(<QuoteRequest>[])
        : ref.watch(customerRequestsProvider(user.uid));

    return InkWell(
      onTap: () => context.push('/notifications'),
      borderRadius: BorderRadius.circular(10),
      child: requestsAsync.when(
        loading: () => const _BellIcon(count: 0),
        error: (_, __) => const _BellIcon(count: 0),
        data: (requests) {
          final pending = requests
              .where((r) => r.status == RequestStatus.quoted)
              .length;
          return _BellIcon(count: pending);
        },
      ),
    );
  }
}

class _BellIcon extends StatelessWidget {
  final int count;
  const _BellIcon({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.navyBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.navyBlue),
        ),
        if (count > 0)
          Positioned(
            top: -2, right: -2,
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(
                color: AppColors.cancelled, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
