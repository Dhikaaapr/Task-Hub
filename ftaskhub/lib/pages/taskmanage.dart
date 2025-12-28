import 'package:flutter/material.dart';
import 'create_task_page.dart';
import '../models/task_hub_service.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../pages/group_detail_page.dart';
import '../pages/create_group_new.dart'; // Import the new create group page
import '../models/user.dart';

const Color primaryBlue = Color(0xFF0A2E5C);

class TaskItem {
  final String personName;
  final String role;
  final String subtitle1;
  final String subtitle2;
  final String dayLabel;
  final String dateNumber;
  final String monthYear;

  TaskItem({
    required this.personName,
    required this.role,
    required this.subtitle1,
    required this.subtitle2,
    required this.dayLabel,
    required this.dateNumber,
    required this.monthYear,
  });
}

// dummy data untuk awal
List<TaskItem> dummyTasks = [
  TaskItem(
    personName: 'Andhika Presha Saputra',
    role: 'UI/UX Design',
    subtitle1: 'Navigation Bar',
    subtitle2: 'Profile Menu',
    dayLabel: 'Monday',
    dateNumber: '1',
    monthYear: 'February 2025',
  ),
];

/// 🔥 Tempat menyimpan group
List<Map<String, dynamic>> userGroups = [];

/// function tambah group ke Task List
void addGroupToTasks(String groupName, List<String> members) {
  userGroups.add({
    "groupName": groupName,
    "members": members,
    "createdAt": DateTime.now(),
  });
}

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final bool showShadow;

  const TaskCard({super.key, required this.task, this.showShadow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(18),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanggal Style
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.dayLabel,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  task.dateNumber,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.monthYear,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Detail Task
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${task.personName} Task",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.role,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  "• ${task.subtitle1}",
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  "• ${task.subtitle2}",
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MustToDoPage extends StatefulWidget {
  const MustToDoPage({super.key});

  @override
  State<MustToDoPage> createState() => _MustToDoPageState();
}

class _MustToDoPageState extends State<MustToDoPage> {
  final TaskHubService _taskHubService = TaskHubService();

  @override
  void initState() {
    super.initState();
    _taskHubService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Get tasks assigned to current user
    final userTasks = _taskHubService.getTasksByUser('current_user_id');

    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: const Text('All Tasks'),
        backgroundColor: primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.groups),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GroupDetailPage(
                  group: Group(
                    id: 'default_group',
                    name: 'Sample Group',
                    description: 'This is a sample group',
                    memberIds: ['current_user_id'],
                    creatorId: 'current_user_id',
                    createdAt: DateTime.now(),
                  ),
                  currentUser: User(
                    id: 'current_user_id',
                    name: 'Current User',
                    email: 'user@example.com',
                  ),
                )), // Replace with actual group when available
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: () async {
          // Show dialog to choose between creating a task or creating a group
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Create New"),
                content: const Text("What would you like to create?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateTaskPage()),
                      );
                    },
                    child: const Text("Task"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateGroupPageNew()), // Using the new create group page
                      );
                    },
                    child: const Text("Group"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                ],
              );
            },
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your Tasks",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(height: 10),

              if (userTasks.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No tasks assigned to you",
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...userTasks.map(
                  (task) => _buildTaskCard(task),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${task.progress}%",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: task.progress / 100,
                    strokeWidth: 3,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Detail Task
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.status.toString().split('.').last,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "• ${task.description}",
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  "Group: ${task.groupId}", // This should be the group name, but for now using ID
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

