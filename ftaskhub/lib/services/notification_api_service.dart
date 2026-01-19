import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_taskhub/models/notification.dart';

class NotificationApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  String? _token;

  // Set the authentication token
  void setToken(String token) {
    _token = token;
  }

  // Get all notifications for the current user
  Future<List<Notification>> getUserNotifications() async {
    if (_token == null) {
      throw Exception('Authentication token not set');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      return (data['data'] as List)
          .map((json) => Notification.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  // Get unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    if (_token == null) {
      throw Exception('Authentication token not set');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'];
    } else {
      throw Exception('Failed to get unread count: ${response.statusCode}');
    }
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (_token == null) {
      throw Exception('Authentication token not set');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read: ${response.statusCode}');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    if (_token == null) {
      throw Exception('Authentication token not set');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/notifications/mark-all-read'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
    }
  }

  // Create a new notification
  Future<String> createNotification(Notification notification) async {
    if (_token == null) {
      throw Exception('Authentication token not set');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': notification.userId,
        'title': notification.title,
        'message': notification.message,
        'type': _mapNotificationTypeToString(notification.type),
        'data': notification.data,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body)['data']['id'];
    } else {
      throw Exception('Failed to create notification: ${response.statusCode}');
    }
  }

  // Helper method to map notification type to string
  String _mapNotificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.groupJoin:
        return 'group_join';
      case NotificationType.taskDeadline:
        return 'task_deadline';
      case NotificationType.taskAssignment:
        return 'task_assignment';
      case NotificationType.taskUpdate:
        return 'task_update';
      case NotificationType.groupCreated:
        return 'group_created';
      case NotificationType.taskCreated:
        return 'task_created';
      case NotificationType.other:
        return 'other';
    }
  }
}