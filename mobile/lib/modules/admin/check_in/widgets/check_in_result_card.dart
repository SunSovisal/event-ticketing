import 'package:flutter/material.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/status_chip.dart';
import 'package:itc_events/modules/admin/check_in/check_in_outcome.dart';

class CheckInResultCard extends StatelessWidget {
  const CheckInResultCard({super.key, required this.outcome});

  final CheckInOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final color = outcome.isSuccess ? AppTheme.success : AppTheme.warning;
    final attendee = outcome.attendeeName?.trim();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                outcome.isSuccess
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  outcome.message,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusChip.attemptResult(outcome.result),
            ],
          ),
          const Divider(height: 24),
          if (attendee != null && attendee.isNotEmpty) ...[
            _DetailRow(label: 'Attendee', value: attendee),
            const SizedBox(height: 8),
          ],
          if (outcome.eventTitle != null && outcome.eventTitle!.isNotEmpty) ...[
            _DetailRow(label: 'Event', value: outcome.eventTitle!),
            const SizedBox(height: 8),
          ],
          _DetailRow(label: 'Ticket', value: outcome.ticketCode),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Method',
            value: outcome.method == 'manual' ? 'Manual' : 'QR',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
