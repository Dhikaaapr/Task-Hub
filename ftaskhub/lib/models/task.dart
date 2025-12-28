enum TaskStatus { todo, inProgress, done, cancelled }
enum TaskPriority { low, medium, high, urgent }

class Task {
  final String id;
  final String title;
  final String description;
  final String groupId;
  final String assigneeId; // User ID of the assignee
  final String createdBy;   // User ID of the creator
  final DateTime createdAt;
  final DateTime? dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final List<String> attachments; // URLs or file paths
  final int progress; // 0-100 percentage

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.groupId,
    required this.assigneeId,
    required this.createdBy,
    required this.createdAt,
    this.dueDate,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.attachments = const [],
    this.progress = 0,
  });

  // Convert Task to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'groupId': groupId,
      'assigneeId': assigneeId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'attachments': attachments,
      'progress': progress,
    };
  }

  // Create Task from Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      groupId: map['groupId'] ?? '',
      assigneeId: map['assigneeId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'todo'),
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == (map['priority'] ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      attachments: List<String>.from(map['attachments'] ?? []),
      progress: map['progress']?.toInt() ?? 0,
    );
  }

  // Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) => Task.fromMap(json);
  
  // Convert Task to JSON
  Map<String, dynamic> toJson() => toMap();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? groupId,
    String? assigneeId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    List<String>? attachments,
    int? progress,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      groupId: groupId ?? this.groupId,
      assigneeId: assigneeId ?? this.assigneeId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      progress: progress ?? this.progress,
    );
  }
}