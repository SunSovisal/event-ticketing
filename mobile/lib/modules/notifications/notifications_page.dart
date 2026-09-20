import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_card.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/app/widgets/empty_state_view.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/modules/notifications/models/inbox_notification.dart';
import 'package:itc_events/modules/notifications/notification_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = Get.find<NotificationController>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppPageBar(
        title: 'notifications'.tr,
        actions: [
          Obx(() {
            if (inbox.unreadCount.value <= 0) {
              return const SizedBox.shrink();
            }
            return TextButton(
              key: const Key('notifications_mark_all_read'),
              onPressed: inbox.markAllRead,
              child: Text('mark_all_read'.tr),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (inbox.showInitialLoading) {
          return LoadingView(message: 'loading_notifications'.tr);
        }

        if (inbox.errorMessage.value != null && inbox.items.isEmpty) {
          return EmptyStateView(
            icon: Icons.error_outline,
            message: inbox.errorMessage.value!,
            actionLabel: 'retry'.tr,
            onAction: inbox.fetchNotifications,
          );
        }

        final items = inbox.items;
        if (items.isEmpty) {
          return EmptyStateView(
            icon: Icons.notifications_none_outlined,
            message: 'no_notifications'.tr,
            subtitle: 'no_notifications_subtitle'.tr,
          );
        }

        return RefreshIndicator(
          onRefresh: inbox.fetchNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _NotificationTile(
                notification: item,
                onTap: () => inbox.open(item),
              );
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final InboxNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
      color: AppTheme.textPrimaryOf(context),
    );

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: unread ? 0.16 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: titleStyle),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  EventDate.formatRelative(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          if (unread) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
