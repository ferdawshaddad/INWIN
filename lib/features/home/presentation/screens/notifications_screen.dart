import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/quote_request.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/request_service.dart';
import '../../../../core/utils/date_utils.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: Text('Non connecté')));

    final requestsAsync = ref.watch(customerRequestsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (requests) {
          // In a real app, you might have a dedicated notifications collection.
          // For now, we derive "notifications" from requests that need attention (quoted)
          // or have been recently updated.
          final notifications = requests.where((r) => r.status != RequestStatus.pending).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('Aucune notification pour le moment',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final req = notifications[i];
              return _NotificationTile(request: req);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final QuoteRequest request;
  const _NotificationTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final isQuoted = request.status == RequestStatus.quoted;

    return InkWell(
      onTap: () => context.push('/projects/${request.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isQuoted ? AppColors.navyBlue.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isQuoted ? AppColors.navyBlue.withValues(alpha: 0.1) : AppColors.divider,
            width: isQuoted ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _colorForStatus(request.status).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForStatus(request.status),
                color: _colorForStatus(request.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _titleForStatus(request.status),
                        style: TextStyle(
                          fontWeight: isQuoted ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isQuoted)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.lightGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Votre projet "${request.details['category'] ?? request.details['eventType']}" ${_bodyForStatus(request.status)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppDateUtils.relative(request.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.quoted: return 'Devis reçu';
      case RequestStatus.reviewing: return 'Projet en revue';
      case RequestStatus.accepted: return 'Projet accepté';
      case RequestStatus.inProduction: return 'En production';
      case RequestStatus.delivered: return 'Projet livré';
      default: return 'Mise à jour projet';
    }
  }

  String _bodyForStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.quoted: return 'a un nouveau devis prêt pour vous.';
      case RequestStatus.reviewing: return 'est en cours d\'examen par notre équipe.';
      case RequestStatus.accepted: return 'a été validé avec succès.';
      case RequestStatus.inProduction: return 'est maintenant en fabrication.';
      case RequestStatus.delivered: return 'a été livré. Merci de votre confiance !';
      default: return 'a été mis à jour.';
    }
  }

  IconData _iconForStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.quoted: return Icons.local_offer_outlined;
      case RequestStatus.reviewing: return Icons.search;
      case RequestStatus.accepted: return Icons.check_circle_outline;
      case RequestStatus.inProduction: return Icons.precision_manufacturing_outlined;
      case RequestStatus.delivered: return Icons.local_shipping_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorForStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.quoted: return AppColors.quoted;
      case RequestStatus.reviewing: return AppColors.navyBlue;
      case RequestStatus.accepted: return AppColors.accepted;
      case RequestStatus.delivered: return AppColors.accepted;
      default: return AppColors.textHint;
    }
  }
}
