import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/firestore_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider() {
    _init();
  }

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  StreamSubscription<User?>? _authSub;
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get notifications => _items;

  int get unreadCount {
    return _items.where((n) {
      final isRead = n['isRead'];
      if (isRead is bool) return !isRead;
      return true; // kalau field belum ada, anggap unread
    }).length;
  }

  void _init() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _start(user.uid);
      } else {
        _stop();
      }
    });
  }

  void _start(String uid) {
    _sub?.cancel();
    _sub = FirestoreService().streamMyNotifications(limit: 50).listen((items) {
      _items = items;
      notifyListeners();
    });
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _items = [];
    notifyListeners();
  }

  void start() {
    // Deprecated: logic moved to _init()
  }

  void stop() {
    // Deprecated: logic handled by _init()
  }

  Future<void> markAsRead(String id) async {
     await FirestoreService().markNotificationAsRead(id);
  }

  Future<void> markAllAsRead() async {
    await FirestoreService().markAllNotificationsAsRead();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }


}
