import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:flutter_taskhub/models/notification.dart';
import 'package:flutter_taskhub/services/notification_service.dart';

final _log = Logger('NotificationProvider');

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<Notification> _notifications = [];
  int _unreadCount = 0;
  String? _currentUserId;
  Timer? _pollingTimer;

  List<Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  // Initialize the provider with a user ID
  void initialize(String userId, {String? token}) {
    _currentUserId = userId;
    if (token != null) {
      _notificationService.setToken(token);
    }
    _startPolling();
  }

  // Start polling for notifications
  void _startPolling() {
    if (_currentUserId == null) return;

    // Initial load
    _loadNotifications();

    // Set up polling every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadNotifications();
    });
  }

  // Load notifications for the current user
  Future<void> _loadNotifications() async {
    if (_currentUserId == null) return;

    try {
      final notifications = await _notificationService.getUserNotifications(_currentUserId!);
      _notifications = notifications;
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      _log.warning('Error loading notifications: $e');
    }
  }

  // Update the unread count
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((notification) => !notification.isRead).length;
    notifyListeners();
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markNotificationAsRead(notificationId);
    // Update the local notification status
    final index = _notifications.indexWhere((notification) => notification.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    await _notificationService.markAllNotificationsAsRead(_currentUserId!);
    // Update all local notifications to read
    _notifications = _notifications.map((notification) =>
      notification.copyWith(isRead: true)
    ).toList();
    _updateUnreadCount();
    notifyListeners();
  }

  // Get a specific notification
  Notification? getNotification(String id) {
    try {
      return _notifications.firstWhere((notification) => notification.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh the notifications
  Future<void> refresh() async {
    await _loadNotifications();
  }

  // Dispose of the timer when the provider is disposed
  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}