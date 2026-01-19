import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/notification_provider.dart';
import 'group_detail_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, p, child) {
              if (p.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: () => p.markAllAsRead(),
                  tooltip: 'Mark all as read',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, p, child) {
          final notifications = p.notifications;

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index]; // Map<String, dynamic>
              return _NotificationItem(
                data: n,
                onTap: () => _handleTap(context, n),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, Map<String, dynamic> n) async {
    final p = Provider.of<NotificationProvider>(context, listen: false);

    final id = (n['id'] ?? '').toString();
    if (id.isNotEmpty) {
      await p.markAsRead(id);
    }

    // kalau ada groupId, buka group detail
    final groupId = (n['groupId'] ?? '').toString();
    if (groupId.isNotEmpty) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupDetailPage(groupId: groupId)),
      );
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _NotificationItem({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = (data['title'] ?? '-').toString();
    final message = (data['message'] ?? '').toString();
    final type = (data['type'] ?? 'general').toString();

    final isReadVal = data['isRead'];
    final isRead = isReadVal is bool ? isReadVal : false;
    final isUnread = !isRead;

    DateTime createdAt = DateTime.now();
    final ca = data['createdAt'];
    if (ca is Timestamp) createdAt = ca.toDate();
    if (ca is DateTime) createdAt = ca;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isUnread ? 4 : 2,
      color: isUnread
          ? theme.cardColor.withValues(alpha: 0.95)
          : theme.cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _iconByType(type),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              _formatTime(createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            message,
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

  Widget _iconByType(String type) {
    // mapping string -> icon
    IconData icon;
    Color color;

    switch (type) {
      case 'groupJoin':
      case 'groupCreated':
        icon = Icons.group;
        color = Colors.blue;
        break;

      case 'taskDeadline':
        icon = Icons.access_time;
        color = Colors.orange;
        break;

      case 'taskAssignment':
        icon = Icons.assignment;
        color = Colors.green;
        break;

      case 'taskUpdate':
        icon = Icons.update;
        color = Colors.purple;
        break;

      case 'taskCreated':
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
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
