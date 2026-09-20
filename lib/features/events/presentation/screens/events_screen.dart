import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/auth_service.dart';

const _b2bEventTypes = [
  {
    'id': 'seminaire',
    'label': 'Séminaire',
    'sub': 'Réunion de travail et échanges',
    'icon': LucideIcons.users,
  },
  {
    'id': 'team_building',
    'label': 'Team Building',
    'sub': 'Activités de cohésion d\'équipe',
    'icon': LucideIcons.trophy,
  },
  {
    'id': 'lancement_produit',
    'label': 'Lancement Produit',
    'sub': 'Présentation de vos nouveautés',
    'icon': LucideIcons.rocket,
  },
  {
    'id': 'conference',
    'label': 'Conférence',
    'sub': 'Prise de parole et débats',
    'icon': LucideIcons.mic,
  },
  {
    'id': 'inauguration',
    'label': 'Inauguration',
    'sub': 'Célébration d\'ouverture',
    'icon': LucideIcons.partyPopper,
  },
  {
    'id': 'fete_annuelle',
    'label': 'Fête Annuelle',
    'sub': 'Événement annuel d\'entreprise',
    'icon': LucideIcons.star,
  },
];

const _b2cEventTypes = [
  {
    'id': 'bride_to_be',
    'label': 'Bride to be',
    'sub': 'Organisation de votre fête EVJF',
    'icon': LucideIcons.gem,
  },
  {
    'id': 'anniversaire',
    'label': 'Anniversaire',
    'sub': 'Fête d\'anniversaire personnalisée',
    'icon': LucideIcons.cake,
  },
  {
    'id': 'fete_traditionnelle',
    'label': 'Fête traditionnelle',
    'sub': 'Hammam, Outia, Circoncision...',
    'icon': LucideIcons.sparkles,
  },
  {
    'id': 'baby_shower',
    'label': 'Baby shower',
    'sub': 'Célébration pour le nouveau-né',
    'icon': LucideIcons.baby,
  },
  {
    'id': 'fiancailles',
    'label': 'Fiançailles',
    'sub': 'Organisation de votre cérémonie',
    'icon': LucideIcons.gem,
  },
  {
    'id': 'fete_privee',
    'label': 'Soirée privée',
    'sub': 'Dîners, réceptions, soirées',
    'icon': LucideIcons.glassWater,
  },
];

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isB2B = user?.clientType.isB2B ?? true;
    final events = isB2B ? _b2bEventTypes : _b2cEventTypes;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Événements')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final ev = events[i];
          final iconData = ev['icon'] as IconData;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border:
                  Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            child: InkWell(
              onTap: () => context.go(
                isB2B
                    ? '/events/${ev['id']}'
                    : '/events/b2c?category=${ev['id']}',
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.navyBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconData,
                        size: 22,
                        color: AppColors.navyBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev['label'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ev['sub'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
