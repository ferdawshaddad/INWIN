import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/quote_request.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/request_service.dart';
import '../../../../core/utils/snack_utils.dart';
import '../../../../core/widgets/status_badge.dart';
import '../widgets/notification_badge.dart';
import '../widgets/trusted_clients_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final requestsAsync = ref.watch(customerRequestsProvider(user.uid));
        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bonjour,',
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text(
                              '${user.fullName.split(' ').first} ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(fontSize: 26),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const NotificationBell(),
                    ],
                  ),
                ),
              ),
              // Request a quote section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  child: Text('Demander un devis',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              if (user.clientType == ClientType.b2b) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            label: 'Cadeaux d\'affaires',
                            imageAsset: 'assets/images/Gift icon.png',
                            color: AppColors.navyBlue,
                            onTap: () => context.go('/gifts'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickActionCard(
                            label: 'Événements Corporate',
                            imageAsset: 'assets/images/event icon.jpg',
                            color: AppColors.lightGold,
                            onTap: () => context.go('/events'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _QuickActionCardFullWidth(
                      label: 'Organiser un événement',
                      imageAsset: 'assets/images/event icon.jpg',
                      color: AppColors.lightGold,
                      onTap: () => context.go('/events'),
                    ),
                  ),
                ),
              ],
              // Recent requests
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Projets récents',
                          style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go('/projects'),
                        child: const Text('Voir tout',
                            style: TextStyle(color: AppColors.lightGold)),
                      ),
                    ],
                  ),
                ),
              ),
              requestsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )),
                ),
                error: (e, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                        child: Text('Erreur: $e',
                            style: const TextStyle(color: Colors.red))),
                  ),
                ),
                data: (requests) {
                  if (requests.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyState(
                        onTap: () => context.go(
                          user.clientType == ClientType.b2b ? '/gifts' : '/events',
                        ),
                      ),
                    );
                  }
                  final recent = requests.take(3).toList();
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _RequestCard(
                        request: recent[i],
                        onTap: () => context.go('/projects/${recent[i].id}'),
                      ),
                      childCount: recent.length,
                    ),
                  );
                },
              ),
              // ── Trusted clients carousel ──────────────────────────────────
              const SliverToBoxAdapter(
                child: TrustedClientsSection(),
              ),
              // Talk to expert banner
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                  child: _ExpertBanner(),
                ),
              ),
              // Testimonials Section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                  child: _TestimonialsSection(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final String? imageAsset;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.label,
    this.imageAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              Image.asset(imageAsset!, width: 85, height: 85),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCardFullWidth extends StatelessWidget {
  final String label;
  final String? imageAsset;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCardFullWidth({
    required this.label,
    this.imageAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            if (imageAsset != null)
              Image.asset(imageAsset!, width: 100, height: 100),
          ],
        ),
      ),
    );
  }
}

class _ExpertBanner extends StatelessWidget {
  const _ExpertBanner();

  Future<void> _contactSupport(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'inwin.services@gmail.com',
      queryParameters: {'subject': 'Demande d\'assistance INWIN'},
    );

    final launched = await launchUrl(
      emailUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      SnackUtils.info(
        context,
        'Aucune application e-mail disponible sur cet appareil.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navyBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.lightGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.headset_mic_outlined,
                color: AppColors.lightGold, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Besoin d\'aide ?',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('Parlez à un expert INWIN',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 104),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ElevatedButton(
                onPressed: () => _contactSupport(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Contacter'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  @override
  Widget build(BuildContext context) {
    final testimonials = [
      (
        'Sami B.',
        'Directeur Marketing',
        'Service impeccable ! Les coffrets cadeaux pour nos partenaires étaient de très haute qualité.',
        'https://ui-avatars.com/api/?name=Sami+B&background=002147&color=fff'
      ),
      (
        'Amira K.',
        'RH Manager',
        'L\'organisation de notre team building était parfaite. Équipe réactive et à l\'écoute.',
        'https://ui-avatars.com/api/?name=Amira+K&background=C5A059&color=fff'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Témoignages', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: testimonials.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final (name, role, text, avatar) = testimonials[i];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(avatar),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                role,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textHint, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const Text(' 5.0',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      text,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontStyle: FontStyle.italic),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final QuoteRequest request;
  final VoidCallback onTap;
  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: request.type == RequestType.gift
                      ? AppColors.navyBlue.withValues(alpha: 0.08)
                      : AppColors.lightGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  request.type == RequestType.gift
                      ? Icons.card_giftcard_outlined
                      : Icons.event_outlined,
                  color: request.type == RequestType.gift
                      ? AppColors.navyBlue
                      : AppColors.lightGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
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
                      request.details['material'] ??
                          request.details['location'] ??
                          '',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatusBadge(status: request.status, small: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined,
                size: 36, color: AppColors.navyBlue),
          ),
          const SizedBox(height: 16),
          Text('Aucun projet pour le moment',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Commencez par créer votre première demande de devis.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Créer une demande'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
          ),
        ],
      ),
    );
  }
}
