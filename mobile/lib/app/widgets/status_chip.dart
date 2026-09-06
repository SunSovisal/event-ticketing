import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusChip.eventStatus(String status) {
    switch (status) {
      case 'published':
        return StatusChip(label: 'status_published'.tr, color: AppTheme.success);
      case 'draft':
        return StatusChip(label: 'status_draft'.tr, color: AppTheme.primary);
      case 'cancelled':
        return StatusChip(label: 'status_cancelled'.tr, color: AppTheme.error);
      default:
        return StatusChip(label: status, color: AppTheme.textSecondary);
    }
  }

  factory StatusChip.ticketStatus(String status) {
    switch (status) {
      case 'valid':
        return StatusChip(label: 'status_valid'.tr, color: AppTheme.success);
      case 'checked_in':
        return StatusChip(
          label: 'status_checked_in'.tr,
          color: AppTheme.primary,
        );
      case 'cancelled':
        return StatusChip(label: 'status_cancelled'.tr, color: AppTheme.error);
      case 'ended':
        return StatusChip(
          label: 'status_ended'.tr,
          color: AppTheme.textSecondary,
        );
      default:
        return StatusChip(label: status, color: AppTheme.textSecondary);
    }
  }

  factory StatusChip.attemptResult(String result) {
    switch (result) {
      case 'success':
        return StatusChip(label: 'status_success'.tr, color: AppTheme.success);
      case 'already_checked_in':
        return StatusChip(
          label: 'status_duplicate'.tr,
          color: AppTheme.warning,
        );
      case 'not_found':
        return StatusChip(label: 'status_not_found'.tr, color: AppTheme.error);
      case 'cancelled':
        return StatusChip(label: 'status_cancelled'.tr, color: AppTheme.error);
      case 'event_cancelled':
        return StatusChip(
          label: 'status_event_cancelled'.tr,
          color: AppTheme.error,
        );
      case 'too_early':
        return StatusChip(label: 'status_too_early'.tr, color: AppTheme.warning);
      case 'too_late':
        return StatusChip(label: 'status_too_late'.tr, color: AppTheme.warning);
      default:
        return StatusChip(label: result, color: AppTheme.textSecondary);
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
          fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
          fontWeight:
              Theme.of(context).textTheme.bodySmall?.fontFamily ==
                  AppTheme.khmerFontFamily
              ? FontWeight.w400
              : FontWeight.w600,
        ),
      ),
    );
  }
}
