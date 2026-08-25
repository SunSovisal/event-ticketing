import 'package:flutter/material.dart';
import 'package:itc_events/app/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusChip.eventStatus(String status) {
    switch (status) {
      case 'published':
        return StatusChip(label: 'Published', color: AppTheme.success);
      case 'draft':
        return StatusChip(label: 'Draft', color: AppTheme.primary);
      case 'cancelled':
        return StatusChip(label: 'Cancelled', color: AppTheme.error);
      default:
        return StatusChip(label: status, color: AppTheme.textSecondary);
    }
  }

  factory StatusChip.ticketStatus(String status) {
    switch (status) {
      case 'valid':
        return StatusChip(label: 'Valid', color: AppTheme.success);
      case 'checked_in':
        return StatusChip(label: 'Checked in', color: AppTheme.primary);
      case 'cancelled':
        return StatusChip(label: 'Cancelled', color: AppTheme.error);
      default:
        return StatusChip(label: status, color: AppTheme.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
