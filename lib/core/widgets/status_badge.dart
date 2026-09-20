import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/quote_request.dart';

class StatusBadge extends StatelessWidget {
  final RequestStatus status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  Color get _bg {
    switch (status) {
      case RequestStatus.pending: return AppColors.pending.withValues(alpha: 0.15);
      case RequestStatus.reviewing: return Colors.orange.withValues(alpha: 0.15);
      case RequestStatus.quoted: return AppColors.quoted.withValues(alpha: 0.15);
      case RequestStatus.accepted: return AppColors.accepted.withValues(alpha: 0.15);
      case RequestStatus.rejected: return AppColors.cancelled.withValues(alpha: 0.15);
      case RequestStatus.inProduction: return AppColors.inProduction.withValues(alpha: 0.15);
      case RequestStatus.delivered: return AppColors.delivered.withValues(alpha: 0.15);
      case RequestStatus.cancelled: return AppColors.cancelled.withValues(alpha: 0.15);
    }
  }

  Color get _fg {
    switch (status) {
      case RequestStatus.pending: return const Color(0xFFE65100);
      case RequestStatus.reviewing: return Colors.orange.shade800;
      case RequestStatus.quoted: return const Color(0xFF0D47A1);
      case RequestStatus.accepted: return const Color(0xFF1B5E20);
      case RequestStatus.rejected: return const Color(0xFFB71C1C);
      case RequestStatus.inProduction: return const Color(0xFF4A148C);
      case RequestStatus.delivered: return const Color(0xFF004D40);
      case RequestStatus.cancelled: return const Color(0xFFB71C1C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _fg,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
