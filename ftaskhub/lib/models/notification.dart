// lib/models/notification.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// NOTE:
/// Nama file ini "notification.dart" aman, tapi class-nya jangan pakai nama "Notification"
/// biar tidak bentrok dengan Flutter Notification.
/// Kita pakai AppNotification.

enum NotificationType {
  taskDeadline,
  taskAssignment,
  taskCreated,
  taskUpdate,
  groupJoin,
  groupCreated,
  other,
}

NotificationType notificationTypeFromString(String? s) {
  if (s == null) return NotificationType.other;
  switch (s) {
    case 'taskDeadline':
      return NotificationType.taskDeadline;
    case 'taskAssignment':
      return NotificationType.taskAssignment;
    case 'taskCreated':
      return NotificationType.taskCreated;
    case 'taskUpdate':
      return NotificationType.taskUpdate;
    case 'groupJoin':
      return NotificationType.groupJoin;
    case 'groupCreated':
      return NotificationType.groupCreated;
    default:
      return NotificationType.other;
  }
}

String notificationTypeToString(NotificationType t) {
  // penting: konsisten dengan yang disimpan di FirestoreService (_createUserNotification)
  return t.name; // Dart >= 2.15
}

class AppNotification {
  final String id;

  final NotificationType type;
  final String title;
  final String message;

  final bool isRead;
  final DateTime createdAt;

  /// Optional: untuk deep link ke halaman tertentu
  final String? groupId;
  final String? taskId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.groupId,
    this.taskId,
  });

  /// Dari Map firestore -> model
  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];

    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    } else {
      createdAt = DateTime.now();
    }

    return AppNotification(
      id: id,
      type: notificationTypeFromString(data['type']?.toString()),
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      isRead: (data['isRead'] ?? false) == true,
      createdAt: createdAt,
      groupId: data['groupId']?.toString(),
      taskId: data['taskId']?.toString(),
    );
  }

  /// Model -> Map firestore
  Map<String, dynamic> toMap() {
    return {
      'type': notificationTypeToString(type),
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (groupId != null) 'groupId': groupId,
      if (taskId != null) 'taskId': taskId,
    };
  }

  AppNotification copyWith({
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? groupId,
    String? taskId,
  }) {
    return AppNotification(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      taskId: taskId ?? this.taskId,
    );
  }
}
