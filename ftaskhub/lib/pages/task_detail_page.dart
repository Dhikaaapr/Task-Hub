import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../models/user.dart';
import '../models/task_hub_service.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;
  final Group group;
  final User currentUser;

  const TaskDetailPage({
    super.key,
    required this.task,
    required this.group,
    required this.currentUser,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final TaskHubService _taskHubService = TaskHubService();
  late Task _task;
  late int _progressValue;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _progressValue = _task.progress;
  }

  @override
  Widget build(BuildContext context) {
    final assignee = _taskHubService.getUserById(_task.assigneeId);
    final creator = _taskHubService.getUserById(_task.createdBy);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _task.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (widget.currentUser.id == widget.group.creatorId || 
              widget.currentUser.id == _task.assigneeId)
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'edit') {
                  // Handle edit
                } else if (result == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit Task'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete Task', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task status and priority
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_task.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(_task.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_task.priority),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getPriorityText(_task.priority),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Task title
            Text(
              _task.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2E5C),
              ),
            ),
            const SizedBox(height: 8),

            // Assignee
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 16,
                  color: Color(0xFF0A2E5C),
                ),
                const SizedBox(width: 8),
                Text(
                  'Assigned to: ${assignee?.name ?? "Unknown"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0A2E5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.person_add,
                  size: 16,
                  color: Color(0xFF0A2E5C),
                ),
                const SizedBox(width: 8),
                Text(
                  'Created by: ${creator?.name ?? "Unknown"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0A2E5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Due date
            if (_task.dueDate != null)
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF0A2E5C),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ${DateFormat('dd/MM/yyyy').format(_task.dueDate!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A2E5C),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2E5C),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _task.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progress section
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2E5C),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _progressValue.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_progressValue.round()}%',
                    activeColor: const Color(0xFF0A2E5C),
                    inactiveColor: Colors.grey[300],
                    onChanged: widget.currentUser.id == widget.group.creatorId || 
                               widget.currentUser.id == _task.assigneeId
                        ? (double value) {
                            setState(() {
                              _progressValue = value.round();
                            });
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_progressValue.round()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2E5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _task.progress != 100
                      ? () {
                          setState(() {
                            _progressValue = 100;
                          });
                        }
                      : null,
                  child: const Text(
                    'Mark Complete',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _updateProgress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2E5C),
                  ),
                  child: const Text('Save Progress'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Additional info
            const Text(
              'Task Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2E5C),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoTile('Group', widget.group.name),
            _buildInfoTile(
              'Created',
              DateFormat('dd/MM/yyyy HH:mm').format(_task.createdAt),
            ),
            if (_task.attachments.isNotEmpty)
              _buildInfoTile('Attachments', '${_task.attachments.length} files'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateProgress() {
    TaskStatus newStatus = _task.status;

    // Automatically update status based on progress
    if (_progressValue == 100) {
      newStatus = TaskStatus.done;
    } else if (_progressValue > 0 && _progressValue < 100) {
      newStatus = TaskStatus.inProgress;
    } else if (_progressValue == 0) {
      newStatus = TaskStatus.todo;
    }

    final updatedTask = _task.copyWith(
      progress: _progressValue,
      status: newStatus,
    );

    _taskHubService.updateTask(updatedTask);
    setState(() {
      _task = updatedTask;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progress updated successfully'),
        backgroundColor: Color(0xFF0A2E5C),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _taskHubService.deleteTask(_task.id);
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Go back to previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted successfully'),
                    backgroundColor: Color(0xFF0A2E5C),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}