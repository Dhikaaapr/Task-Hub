import 'package:flutter/material.dart';
import 'package:flutter_taskhub/models/notification.dart' as app_notification;
import 'package:flutter_taskhub/services/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              if (notificationProvider.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.markunread_mailbox),
                  onPressed: () => notificationProvider.markAllAsRead(),
                  tooltip: 'Mark all as read',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final notifications = notificationProvider.notifications;

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationItem(
                notification: notification,
                onTap: () => _handleNotificationTap(context, notification),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, app_notification.Notification notification) {
    // Mark notification as read
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.markAsRead(notification.id);

    // Navigate to the appropriate page based on notification type
    switch (notification.type) {
      case app_notification.NotificationType.taskDeadline:
      case app_notification.NotificationType.taskAssignment:
      case app_notification.NotificationType.taskCreated:
        // Navigate to task details page
        // _navigateToTaskDetails(context, notification);
        break;
      case app_notification.NotificationType.groupJoin:
      case app_notification.NotificationType.groupCreated:
        // Navigate to group details page
        // _navigateToGroupDetails(context, notification);
        break;
      default:
        // Handle other notification types
        break;
    }
  }
}

class NotificationItem extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback? onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isUnread ? 4 : 2,
      color: isUnread ? theme.cardColor.withValues(alpha: 0.9) : theme.cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _getNotificationIcon(notification.type),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            notification.message,
            style: TextStyle(
              color: isUnread ? Colors.black87 : Colors.grey[700],
            ),
          ),
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _getNotificationIcon(app_notification.NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case app_notification.NotificationType.groupJoin:
      case app_notification.NotificationType.groupCreated:
        icon = Icons.group;
        color = Colors.blue;
        break;
      case app_notification.NotificationType.taskDeadline:
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case app_notification.NotificationType.taskAssignment:
        icon = Icons.assignment;
        color = Colors.green;
        break;
      case app_notification.NotificationType.taskUpdate:
        icon = Icons.update;
        color = Colors.purple;
        break;
      case app_notification.NotificationType.taskCreated:
        icon = Icons.add_task;
        color = Colors.teal;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}