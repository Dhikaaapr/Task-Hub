import 'dart:math';
import '../models/group.dart';
import '../models/task.dart';
import '../models/user.dart';

class TaskHubService {
  static final TaskHubService _instance = TaskHubService._internal();
  factory TaskHubService() => _instance;
  TaskHubService._internal();

  // In-memory storage for demo purposes
  final List<Group> _groups = [];
  final List<Task> _tasks = [];
  final List<User> _users = [];

  // Initialize with a default user
  void initialize() {
    // Add current user
    if (_users.isEmpty) {
      _users.add(User(
        id: 'current_user_id',
        name: 'Andhika Presha Saputra',
        email: 'andhika@example.com',
        avatarUrl: 'assets/profile.jpg',
      ));
    }
  }

  // Group management
  List<Group> getGroups() => _groups;
  
  Group? getGroupById(String id) => _groups.firstWhere((group) => group.id == id, orElse: () => Group(
    id: '',
    name: '',
    description: '',
    memberIds: [],
    creatorId: '',
    createdAt: DateTime.now(),
  ));

  Group createGroup({
    required String name,
    required String description,
    required String creatorId,
    List<String> memberIds = const [],
  }) {
    final group = Group(
      id: _generateId(),
      name: name,
      description: description,
      creatorId: creatorId,
      memberIds: [creatorId, ...memberIds], // Add creator as first member
      createdAt: DateTime.now(),
    );
    _groups.add(group);
    return group;
  }

  void updateGroup(Group group) {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
    }
  }

  void deleteGroup(String id) {
    _groups.removeWhere((group) => group.id == id);
    // Also remove all tasks related to this group
    _tasks.removeWhere((task) => task.groupId == id);
  }

  // Task management
  List<Task> getTasksByGroup(String groupId) => 
    _tasks.where((task) => task.groupId == groupId).toList();
  
  List<Task> getTasksByUser(String userId) => 
    _tasks.where((task) => task.assigneeId == userId).toList();

  Task createTask({
    required String title,
    required String description,
    required String groupId,
    required String assigneeId,
    required String createdBy,
    DateTime? dueDate,
  }) {
    final task = Task(
      id: _generateId(),
      title: title,
      description: description,
      groupId: groupId,
      assigneeId: assigneeId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );
    _tasks.add(task);
    return task;
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
  }

  // User management
  List<User> getUsers() => _users;
  User? getUserById(String id) => _users.firstWhere((user) => user.id == id, orElse: () => User(
    id: '',
    name: '',
    email: '',
    avatarUrl: '',
  ));

  User createUser({
    required String name,
    required String email,
    String avatarUrl = '',
  }) {
    final user = User(
      id: _generateId(),
      name: name,
      email: email,
      avatarUrl: avatarUrl,
    );
    _users.add(user);
    return user;
  }

  void updateUser(User user) {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
  }

  // Helper functions
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  // Get group members
  List<User> getGroupMembers(String groupId) {
    final group = getGroupById(groupId);
    if (group == null) return [];
    return group.memberIds.map((userId) => getUserById(userId)!).toList();
  }

  // Get tasks by group with status
  List<Task> getTasksByGroupAndStatus(String groupId, TaskStatus status) {
    return _tasks.where((task) => task.groupId == groupId && task.status == status).toList();
  }

  // Update task progress
  void updateTaskProgress(String taskId, int progress) {
    final task = _tasks.firstWhere((task) => task.id == taskId, orElse: () => Task(
      id: '',
      title: '',
      description: '',
      groupId: '',
      assigneeId: '',
      createdBy: '',
      createdAt: DateTime.now(),
    ));
    if (task.id.isNotEmpty) {
      final updatedTask = task.copyWith(progress: progress > 100 ? 100 : progress < 0 ? 0 : progress);
      updateTask(updatedTask);
    }
  }

  // Get group progress percentage
  double getGroupProgress(String groupId) {
    final tasks = getTasksByGroup(groupId);
    if (tasks.isEmpty) return 0.0;
    
    final totalProgress = tasks.fold(0, (sum, task) => sum + task.progress);
    return totalProgress / tasks.length;
  }
}