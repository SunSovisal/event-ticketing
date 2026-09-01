import 'package:flutter/material.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/events/event_category.dart';

/// Horizontally scrolling category filter. [selected] of null means All.
class EventCategoryScroller extends StatelessWidget {
  const EventCategoryScroller({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = ['All', ...EventCategory.values];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = labels[index];
          final value = index == 0 ? null : label;
          final isSelected = selected == value;

          return Material(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => onSelected(value),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.borderOf(context),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textPrimaryOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
