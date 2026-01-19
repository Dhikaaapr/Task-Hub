// Integration test for the notification system
// This file demonstrates how all components work together

import 'package:flutter/material.dart';
import 'package:flutter_taskhub/models/task.dart';
import 'package:flutter_taskhub/services/notification_service.dart';
import 'package:flutter_taskhub/services/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationIntegrationTest extends StatelessWidget {
  const NotificationIntegrationTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Notification System Test',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const NotificationTestPage(),
      ),
    );
  }
}

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final NotificationService _notificationService = NotificationService();
  final String _userId = 'test_user_123'; // Simulated user ID

  @override
  void initState() {
    super.initState();
    
    // Initialize the notification provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.initialize(_userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification System Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationTestPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Notification System Integration Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testGroupJoinNotification,
              child: const Text('Test Group Join Notification'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testTaskDeadlineNotification,
              child: const Text('Test Task Deadline Notification'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testTaskAssignmentNotification,
              child: const Text('Test Task Assignment Notification'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testGroupCreatedNotification,
              child: const Text('Test Group Created Notification'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testTaskCreatedNotification,
              child: const Text('Test Task Created Notification'),
            ),
            const SizedBox(height: 20),
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return Column(
                  children: [
                    Text(
                      'Unread Notifications: ${notificationProvider.unreadCount}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (notificationProvider.notifications.isNotEmpty)
                      Text(
                        'Total Notifications: ${notificationProvider.notifications.length}',
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _testGroupJoinNotification() async {
    try {
      await _notificationService.createGroupJoinNotification(
        userId: _userId,
        groupId: 'group_123',
        groupName: 'Test Group',
      );
      _showSnackBar('Group join notification created successfully');
    } catch (e) {
      _showSnackBar('Error creating group join notification: $e');
    }
  }

  void _testTaskDeadlineNotification() async {
    final task = Task(
      id: 'task_123',
      title: 'Test Task',
      description: 'Test task description',
      groupId: 'group_123',
      assigneeId: _userId,
      createdBy: 'creator_123',
      createdAt: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(hours: 1)),
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
    );

    try {
      await _notificationService.createTaskDeadlineNotification(
        userId: _userId,
        task: task,
        groupName: 'Test Group',
        timeRemaining: '1 hour',
      );
      _showSnackBar('Task deadline notification created successfully');
    } catch (e) {
      _showSnackBar('Error creating task deadline notification: $e');
    }
  }

  void _testTaskAssignmentNotification() async {
    final task = Task(
      id: 'task_123',
      title: 'Test Task',
      description: 'Test task description',
      groupId: 'group_123',
      assigneeId: _userId,
      createdBy: 'creator_123',
      createdAt: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 1)),
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
    );

    try {
      await _notificationService.createTaskAssignmentNotification(
        userId: _userId,
        task: task,
        groupName: 'Test Group',
      );
      _showSnackBar('Task assignment notification created successfully');
    } catch (e) {
      _showSnackBar('Error creating task assignment notification: $e');
    }
  }

  void _testGroupCreatedNotification() async {
    try {
      await _notificationService.createGroupCreatedNotification(
        userId: _userId,
        groupId: 'group_123',
        groupName: 'Test Group',
      );
      _showSnackBar('Group created notification created successfully');
    } catch (e) {
      _showSnackBar('Error creating group created notification: $e');
    }
  }

  void _testTaskCreatedNotification() async {
    final task = Task(
      id: 'task_123',
      title: 'Test Task',
      description: 'Test task description',
      groupId: 'group_123',
      assigneeId: _userId,
      createdBy: 'creator_123',
      createdAt: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 1)),
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
    );

    try {
      await _notificationService.createTaskCreatedNotification(
        userId: _userId,
        task: task,
        groupName: 'Test Group',
      );
      _showSnackBar('Task created notification created successfully');
    } catch (e) {
      _showSnackBar('Error creating task created notification: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}