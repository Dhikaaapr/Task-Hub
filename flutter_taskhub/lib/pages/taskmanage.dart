import 'package:flutter/material.dart';

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

// dummy data untuk Must To Do
final List<TaskItem> dummyTasks = [
  TaskItem(
    personName: 'Andhika Presha Saputra',
    role: 'UI/UX Design',
    subtitle1: 'Navigation Bar',
    subtitle2: 'Profile Menu',
    dayLabel: 'Monday',
    dateNumber: '1',
    monthYear: 'February 2025',
  ),
  TaskItem(
    personName: 'Zaki Maulana',
    role: 'Frontend',
    subtitle1: 'Navigation Bar',
    subtitle2: 'Profile Menu',
    dayLabel: 'Thursday',
    dateNumber: '31',
    monthYear: 'May 2025',
  ),
  TaskItem(
    personName: 'Najuan Al Fariz',
    role: 'Backend',
    subtitle1: 'Navigation Bar',
    subtitle2: 'Profile Menu',
    dayLabel: 'Saturday',
    dateNumber: '24',
    monthYear: 'August 2025',
  ),
];

/// 🔥 List kelompok yang dibuat user
List<Map<String, dynamic>> userGroups = [];

/// tambah group ke Task List
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
          // Tanggal bulat (style A)
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.dayLabel,
                  textAlign: TextAlign.center,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task.personName} Task',
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

class MustToDoPage extends StatelessWidget {
  const MustToDoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: const Text('Must To Do'),
        backgroundColor: primaryBlue,
        elevation: 0,
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
                "Must To Do",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),

              // 🔹 render semua dummy tasks
              ...dummyTasks.map(
                (task) => TaskCard(task: task, showShadow: true),
              ),

              const SizedBox(height: 20),

              if (userGroups.isNotEmpty)
                const Text(
                  "Kelompok Dibuat",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

              ...userGroups.map(
                (group) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group["groupName"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Anggota: ${group["members"].join(", ")}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
