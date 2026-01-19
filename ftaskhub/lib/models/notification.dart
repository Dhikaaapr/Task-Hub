
enum NotificationType {
  groupJoin,
  taskDeadline,
  taskAssignment,
  taskUpdate,
  groupCreated,
  taskCreated,
  other
}

class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert Notification to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create Notification from Map
  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: _parseNotificationType(map['type'] ?? 'other'),
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      isRead: map['is_read'] ?? map['isRead'] ?? false,
      createdAt: DateTime.parse(map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : (map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null),
    );
  }

  // Create Notification from JSON
  factory Notification.fromJson(Map<String, dynamic> json) => Notification.fromMap(json);

  // Convert Notification to JSON
  Map<String, dynamic> toJson() => toMap();

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to parse notification type from string
  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'groupJoin':
      case 'group_join':
        return NotificationType.groupJoin;
      case 'taskDeadline':
      case 'task_deadline':
        return NotificationType.taskDeadline;
      case 'taskAssignment':
      case 'task_assignment':
        return NotificationType.taskAssignment;
      case 'taskUpdate':
      case 'task_update':
        return NotificationType.taskUpdate;
      case 'groupCreated':
      case 'group_created':
        return NotificationType.groupCreated;
      case 'taskCreated':
      case 'task_created':
        return NotificationType.taskCreated;
      default:
        return NotificationType.other;
    }
  }
}

// Notification data classes for different types
class GroupNotificationData {
  final String groupId;
  final String groupName;

  GroupNotificationData({
    required this.groupId,
    required this.groupName,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
    };
  }

  factory GroupNotificationData.fromMap(Map<String, dynamic> map) {
    return GroupNotificationData(
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
    );
  }
}

class TaskNotificationData {
  final String taskId;
  final String taskTitle;
  final String groupId;
  final String groupName;
  final DateTime? dueDate;

  TaskNotificationData({
    required this.taskId,
    required this.taskTitle,
    required this.groupId,
    required this.groupName,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'groupId': groupId,
      'groupName': groupName,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory TaskNotificationData.fromMap(Map<String, dynamic> map) {
    return TaskNotificationData(
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
    );
  }
}