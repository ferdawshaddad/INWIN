import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/quote_request.dart';

/// Summary stats strip shown at the top of the admin dashboard.
class AdminStatsHeader extends StatelessWidget {
  final List<QuoteRequest> requests;

  const AdminStatsHeader({super.key, required this.requests});

  @override
  Widget build(BuildContext context) {
    final pending = requests.where((r) => r.status == RequestStatus.pending).length;
    final quoted  = requests.where((r) => r.status == RequestStatus.quoted).length;
    final active  = requests.where((r) =>
        r.status == RequestStatus.accepted ||
        r.status == RequestStatus.inProduction).length;
    final total   = requests.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(children: [
        _Stat(label: 'Total', value: '$total', color: AppColors.navyBlue),
        _Divider(),
        _Stat(label: 'Attente devis', value: '$pending', color: AppColors.pending),
        _Divider(),
        _Stat(label: 'Devis envoyés', value: '$quoted', color: AppColors.quoted),
        _Divider(),
        _Stat(label: 'En cours', value: '$active', color: AppColors.inProduction),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 0.5, height: 40, color: AppColors.divider);
}
