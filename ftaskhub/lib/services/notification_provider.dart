import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/firestore_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _fs;

  NotificationProvider(this._fs);

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get notifications => _items;

  int get unreadCount {
    return _items.where((n) {
      final isRead = n['isRead'];
      if (isRead is bool) return !isRead;
      return true; // kalau field belum ada, anggap unread
    }).length;
  }

  void start() {
    _sub?.cancel();
    _sub = _fs.streamMyNotifications(limit: 50).listen((items) {
      _items = items;
      notifyListeners();
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> markAsRead(String id) async {
    await _fs.markNotificationAsRead(id);
  }

  Future<void> markAllAsRead() async {
    await _fs.markAllNotificationsAsRead();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
