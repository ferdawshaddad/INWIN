import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/quote_request.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/services/request_service.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const ProjectsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<ProjectsScreen> createState() => _State();
}

class _State extends ConsumerState<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  bool _isArchived(RequestStatus s) =>
      s == RequestStatus.delivered ||
      s == RequestStatus.cancelled ||
      s == RequestStatus.rejected;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isB2B = user.clientType == ClientType.b2b;
    final requestsAsync = ref.watch(customerRequestsProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Projets'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.navyBlue,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.navyBlue,
          indicatorWeight: 2.5,
          tabs: requestsAsync.when(
            loading: () => const [
              Tab(text: 'Projets'),
              Tab(text: 'Archivés'),
            ],
            error: (_, __) => const [
              Tab(text: 'Projets'),
              Tab(text: 'Archivés'),
            ],
            data: (requests) {
              final active =
                  requests.where((r) => !_isArchived(r.status)).length;
              final archived =
                  requests.where((r) => _isArchived(r.status)).length;
              return [
                Tab(text: 'Projets${active > 0 ? ' ($active)' : ''}'),
                Tab(text: 'Archivés${archived > 0 ? ' ($archived)' : ''}'),
              ];
            },
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: requestsAsync.when(
              loading: () => const ShimmerList(count: 5),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (requests) {
                final active =
                    requests.where((r) => !_isArchived(r.status)).toList();
                final archived =
                    requests.where((r) => _isArchived(r.status)).toList();
                return TabBarView(
                  controller: _tab,
                  children: [
                    _ProjectList(
                        requests: active,
                        onNew: () => isB2B
                            ? context.go('/gifts')
                            : context.go('/events/b2c')),
                    _ProjectList(requests: archived, isArchived: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  final List<QuoteRequest> requests;
  final bool isArchived;
  final VoidCallback? onNew;

  const _ProjectList({
    required this.requests,
    this.isArchived = false,
    this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return EmptyState(
        icon: isArchived ? Icons.archive_outlined : Icons.inbox_outlined,
        title: isArchived ? 'Aucun projet archivé' : 'Aucun projet en cours',
        subtitle: isArchived
            ? 'Les projets livrés ou annulés apparaîtront ici.'
            : 'Soumettez une demande pour commencer.',
        actionLabel: isArchived ? null : 'Créer une demande',
        onAction: onNew,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (ctx, i) => _ProjectTile(request: requests[i]),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final QuoteRequest request;
  const _ProjectTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final isEvent = request.type == RequestType.event;
    final isQuoted = request.status == RequestStatus.quoted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => context.go('/projects/${request.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isEvent
                          ? AppColors.lightGold.withValues(alpha: 0.1)
                          : AppColors.navyBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEvent
                          ? Icons.event_outlined
                          : Icons.card_giftcard_outlined,
                      color: isEvent ? AppColors.lightGold : AppColors.navyBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.details['category'] ??
                              request.details['eventType'] ??
                              'Demande',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            request.details['model'],
                            request.details['material'],
                          ]
                              .where(
                                  (v) => v != null && v.toString().isNotEmpty)
                              .join(' · '),
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: request.status, small: true),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (request.details['quantity'] != null) ...[
                    const Icon(Icons.numbers,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      '${request.details['quantity']} unités',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (request.quotedPrice != null) ...[
                    const Icon(Icons.local_offer_outlined,
                        size: 13, color: AppColors.lightGold),
                    const SizedBox(width: 4),
                    Text(
                      '${request.quotedPrice!.toStringAsFixed(0)} TND',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightGold,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy').format(request.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
              // Quote CTA
              if (isQuoted) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.quoted.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.quoted.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_outlined,
                          size: 15, color: AppColors.quoted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Devis de ${request.quotedPrice!.toStringAsFixed(0)} TND en attente de votre réponse',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppColors.quoted),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
