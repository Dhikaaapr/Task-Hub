import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/navigation_helper.dart';
import '../pages/notification_page.dart';

class DashboardHeader extends StatelessWidget {
  DashboardHeader({
    super.key,
    required this.displayName,
    required this.subtitle,
    required this.profileImage,
    required this.onTapProfile,
    this.onTapNotifications,
    FirestoreService? firestoreService,
  }) : _fs = firestoreService ?? _DefaultFirestoreServiceWrapper();

  final String displayName;
  final String subtitle;
  final ImageProvider profileImage;
  final VoidCallback onTapProfile;

  /// Optional override: kalau mau handle custom (misal route lain)
  final VoidCallback? onTapNotifications;

  final FirestoreService _fs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTapProfile,
            child: CircleAvatar(
              radius: 25,
              backgroundImage: profileImage,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Notifications with badge (realtime dari Firestore)
          StreamBuilder<int>(
            stream: _fs.streamUnreadNotificationCount(),
            builder: (context, snap) {
              final unread = (snap.data ?? 0);
              final showBadge = unread > 0;

              return InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap:
                    onTapNotifications ??
                    () {
                      navigateWithFade(context, const NotificationPage());
                    },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications, color: Colors.white),
                      if (showBadge)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: _Badge(count: unread),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Wrapper default biar DashboardHeader bisa dipakai tanpa
/// harus kamu kirim instance FirestoreService dari luar.
class _DefaultFirestoreServiceWrapper extends FirestoreService {
  _DefaultFirestoreServiceWrapper();
}
