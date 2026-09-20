import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/quote_request.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/request_service.dart';
import '../../../../core/widgets/status_badge.dart';
import '../widgets/stats_header.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _State();
}

class _State extends ConsumerState<AdminRequestsScreen> {
  RequestStatus? _filterStatus;
  RequestType? _filterType;
  String? _filterClient;

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(
                text: 'IN',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.lightGold)),
            TextSpan(
                text: 'WIN',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navyBlue)),
            TextSpan(
                text: ' Admin',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
          ]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (allRequests) {
          // Apply filters
          var filtered = allRequests.where((r) {
            if (_filterStatus != null && r.status != _filterStatus) {
              return false;
            }
            if (_filterType != null && r.type != _filterType) return false;
            if (_filterClient != null && r.inferredClientType != _filterClient) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Stats strip
              AdminStatsHeader(requests: allRequests),
              const Divider(height: 1),
              // Filter chips
              _FilterRow(
                selectedStatus: _filterStatus,
                selectedType: _filterType,
                selectedClient: _filterClient,
                onStatusChanged: (s) => setState(() => _filterStatus = s),
                onTypeChanged: (t) => setState(() => _filterType = t),
                onClientChanged: (client) => setState(() => _filterClient = client),
              ),
              const Divider(height: 1),
              // Results count
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Text(
                    '${filtered.length} demande${filtered.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (_filterStatus != null ||
                      _filterType != null ||
                      _filterClient != null)
                    GestureDetector(
                      onTap: () => setState(() {
                        _filterStatus = null;
                        _filterType = null;
                        _filterClient = null;
                      }),
                      child: const Text('Effacer les filtres',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.lightGold)),
                    ),
                ]),
              ),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 56, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text('Aucune demande',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _AdminRequestTile(
                          request: filtered[i],
                          onTap: () =>
                              context.go('/admin/request/${filtered[i].id}'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final RequestStatus? selectedStatus;
  final RequestType? selectedType;
  final String? selectedClient;
  final ValueChanged<RequestStatus?> onStatusChanged;
  final ValueChanged<RequestType?> onTypeChanged;
  final ValueChanged<String?> onClientChanged;

  const _FilterRow({
    required this.selectedStatus,
    required this.selectedType,
    required this.selectedClient,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onClientChanged,
  });

  static const _statusFilters = <String, RequestStatus?>{
    'Tous': null,
    'Attente devis': RequestStatus.pending,
    'En revue': RequestStatus.reviewing,
    'Devis': RequestStatus.quoted,
    'Accepté': RequestStatus.accepted,
    'Production': RequestStatus.inProduction,
    'Livré': RequestStatus.delivered,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _Chip(
            label: 'B2B',
            icon: Icons.business_center_rounded,
            active: selectedClient == 'b2b',
            onTap: () => onClientChanged(selectedClient == 'b2b' ? null : 'b2b'),
          ),
          _Chip(
            label: 'B2C',
            icon: Icons.person_rounded,
            active: selectedClient == 'b2c',
            onTap: () => onClientChanged(selectedClient == 'b2c' ? null : 'b2c'),
          ),
          Container(
              width: 1,
              height: 28,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2)),
          // Type toggle
          _Chip(
            icon: Icons.card_giftcard_rounded,
            active: selectedType == RequestType.gift,
            onTap: () => onTypeChanged(
                selectedType == RequestType.gift ? null : RequestType.gift),
          ),
          _Chip(
            icon: Icons.event_rounded,
            active: selectedType == RequestType.event,
            onTap: () => onTypeChanged(
                selectedType == RequestType.event ? null : RequestType.event),
          ),
          Container(
              width: 1,
              height: 28,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2)),
          ..._statusFilters.entries.map((e) => _Chip(
                label: e.key,
                active: selectedStatus == e.value,
                onTap: () => onStatusChanged(e.value),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;
  const _Chip({this.label, this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.navyBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppColors.navyBlue : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 14,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            if (icon != null && label != null) const SizedBox(width: 4),
            if (label != null)
              Text(label!,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: active ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AdminRequestTile extends StatelessWidget {
  final QuoteRequest request;
  final VoidCallback onTap;
  const _AdminRequestTile({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEvent = request.type == RequestType.event;
    final isNew = request.status == RequestStatus.pending;
    final isB2C = request.inferredClientType == 'b2c';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isEvent
                    ? AppColors.lightGold.withValues(alpha: 0.1)
                    : AppColors.navyBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                      child: Icon(
                    isEvent
                        ? Icons.event_outlined
                        : Icons.card_giftcard_outlined,
                    color: isEvent ? AppColors.lightGold : AppColors.navyBlue,
                    size: 20,
                  )),
                  if (isNew)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: AppColors.cancelled, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            request.customerName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: request.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          isB2C ? Icons.person_outline : Icons.business_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${isB2C ? 'Particulier' : (request.companyName ?? '')}  ·  ${request.details['category'] ?? request.details['eventType'] ?? ''}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(children: [
                      if (request.details['quantity'] != null) ...[
                        const Icon(Icons.tag,
                            size: 11, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text('${request.details['quantity']} u.',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(width: 10),
                      ],
                      if (request.quotedPrice != null) ...[
                        const Icon(Icons.local_offer_outlined,
                            size: 11, color: AppColors.lightGold),
                        const SizedBox(width: 2),
                        Text('${request.quotedPrice!.toStringAsFixed(0)} TND',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.lightGold,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 10),
                      ],
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(request.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textHint),
                      ),
                    ]),
                  ]),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 18),
          ]),
        ),
      ),
    );
  }
}
