import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../utils/navigation_helper.dart';

import 'create_task_page.dart';
import 'create_group_page.dart';

const Color primaryBlue = Color(0xFF0A2E5C);

class MustToDoPage extends StatefulWidget {
  const MustToDoPage({super.key});

  @override
  State<MustToDoPage> createState() => _MustToDoPageState();
}

class _MustToDoPageState extends State<MustToDoPage> {
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: const Text('All Tasks'),
        backgroundColor: primaryBlue,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Create New"),
              content: const Text("What would you like to create?"),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _openCreateTaskPage(); // ✅ FIX: pilih group dulu
                  },
                  child: const Text("Task"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    navigateWithFade(context, const CreateGroupPage());
                  },
                  child: const Text("Group"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          );
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fs.streamMyAssignedTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildError('${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          final tasks = snapshot.data ?? [];

          // sort deadline asc
          tasks.sort((a, b) {
            final da = _toDateTime(a['deadline']);
            final db = _toDateTime(b['deadline']);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });

          // upcoming deadlines (max 5) yang belum done/cancelled
          final upcoming = tasks
              .where((t) => (t['status'] ?? 'todo') != 'done')
              .where((t) => (t['status'] ?? 'todo') != 'cancelled')
              .where((t) => _toDateTime(t['deadline']) != null)
              .take(5)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSectionUpcoming(upcoming),
                const SizedBox(height: 12),
                _buildSectionTasks(tasks),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ helper: buka CreateTaskPage (pilih group dulu kalau lebih dari 1)
  Future<void> _openCreateTaskPage() async {
    final groups = await _fs.streamMyGroups().first;
    if (!mounted) return;

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu belum punya group. Buat group dulu.'),
        ),
      );
      navigateWithFade(context, const CreateGroupPage());
      return;
    }

    if (groups.length == 1) {
      final gid = groups.first['id'] as String;
      navigateWithFade(context, CreateTaskPage(groupId: gid));
      return;
    }

    String selectedGroupId = groups.first['id'] as String;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pilih Group'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedGroupId,
            decoration: const InputDecoration(
              labelText: 'Group',
              border: OutlineInputBorder(),
            ),
            items: groups.map((g) {
              return DropdownMenuItem(
                value: g['id'] as String,
                child: Text((g['name'] ?? 'Unnamed') as String),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              selectedGroupId = v;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2E5C),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                if (!mounted) return;
                navigateWithFade(
                  context,
                  CreateTaskPage(groupId: selectedGroupId),
                );
              },
              child: const Text('Lanjut'),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // UI SECTIONS
  // =========================

  Widget _buildSectionUpcoming(List<Map<String, dynamic>> tasks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upcoming Deadlines",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Tidak ada deadline dekat.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Column(
              children: tasks.map((t) {
                final title = (t['title'] ?? '-') as String;
                final d = _toDateTime(t['deadline']);
                final status = (t['status'] ?? 'todo') as String;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 18, color: primaryBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d == null ? '-' : 'Due: ${_formatDateTime(d)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTasks(List<Map<String, dynamic>> tasks) {
    return Container(
      width: double.infinity,
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
          if (tasks.isEmpty)
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
            Column(children: tasks.map((t) => _buildTaskCard(t)).toList()),
        ],
      ),
    );
  }

  // =========================
  // TASK CARD (Firestore)
  // =========================

  Widget _buildTaskCard(Map<String, dynamic> t) {
    final id = (t['id'] ?? '') as String;
    final title = (t['title'] ?? '-') as String;
    final desc = (t['description'] ?? '') as String;

    final status = (t['status'] ?? 'todo') as String;
    final progress = _toInt(t['progress']);

    final deadline = _toDateTime(t['deadline']);
    final groupId = (t['groupId'] ?? '') as String;

    final isDone = status == 'done';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // progress bubble
          Container(
            width: 78,
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
                  "$progress%",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    value: (progress.clamp(0, 100)) / 100,
                    strokeWidth: 3,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                if (desc.trim().isNotEmpty)
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                const SizedBox(height: 6),
                if (deadline != null)
                  Text(
                    "Deadline: ${_formatDateTime(deadline)}",
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                if (groupId.trim().isNotEmpty)
                  Text(
                    "GroupId: $groupId",
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDone
                              ? Colors.green
                              : Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          isDone ? Icons.check_circle : Icons.done_all,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          isDone ? "Completed" : "Mark Done",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: isDone
                            ? null
                            : () async => _markTaskDone(id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markTaskDone(String taskId) async {
    try {
      await _fs.updateTask(
        taskId: taskId,
        data: {
          'status': 'done',
          'progress': 100,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task selesai ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal update task: $e')));
    }
  }

  // =========================
  // SMALL HELPERS
  // =========================

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Gagal memuat tasks:\n$msg',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return 0;
  }

  DateTime? _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String _formatDateTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return "$dd/$mm/$yy $hh:$mi";
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'todo':
        return Colors.grey;
      case 'inProgress':
        return Colors.orange;
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
