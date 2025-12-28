import 'package:flutter/material.dart';
import '../models/task_hub_service.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/group.dart';

class AssignTaskPage extends StatefulWidget {
  final Group group;
  final User currentUser;

  const AssignTaskPage({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final TaskHubService _taskHubService = TaskHubService();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescriptionController = TextEditingController();
  String? _selectedAssigneeId;
  DateTime _selectedDueDate = DateTime.now();
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    _taskHubService.initialize();
    // By default, the current user is creating a task for themselves
    _selectedAssigneeId = widget.currentUser.id;
  }

  void _createTask() {
    if (_taskTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task title is required")),
      );
      return;
    }

    if (_selectedAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an assignee")),
      );
      return;
    }

    final task = _taskHubService.createTask(
      title: _taskTitleController.text,
      description: _taskDescriptionController.text,
      groupId: widget.group.id,
      assigneeId: _selectedAssigneeId!,
      createdBy: widget.currentUser.id,
      dueDate: _selectedDueDate,
    );

    // Update task with selected priority
    final updatedTask = task.copyWith(
      priority: _selectedPriority,
    );
    _taskHubService.updateTask(updatedTask);

    Navigator.pop(context, updatedTask);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Task assigned successfully"),
        backgroundColor: Color(0xFF0A2E5C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupMembers = _taskHubService.getGroupMembers(widget.group.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Assign Task",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title
            TextField(
              controller: _taskTitleController,
              decoration: InputDecoration(
                labelText: "Task Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Task Description
            TextField(
              controller: _taskDescriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Assign To Member
            const Text(
              "Assign To",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedAssigneeId,
                hint: const Text('Select a member'),
                underline: Container(),
                items: groupMembers.map((user) {
                  return DropdownMenuItem(
                    value: user.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: user.avatarUrl.isNotEmpty
                              ? AssetImage(user.avatarUrl) as ImageProvider
                              : null,
                          backgroundColor: const Color(0xFF0A2E5C),
                          child: user.avatarUrl.isEmpty
                              ? const Icon(Icons.person, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(user.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedAssigneeId = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Priority Selection
            const Text(
              "Priority",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TaskPriority.values.map((priority) {
                return ChoiceChip(
                  label: Text(_getPriorityText(priority)),
                  selected: _selectedPriority == priority,
                  selectedColor: _getPriorityColor(priority),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) _selectedPriority = priority;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Due Date
            const Text(
              "Due Date",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                "${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}",
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (selectedDate != null) {
                  setState(() {
                    _selectedDueDate = selectedDate;
                  });
                }
              },
            ),

            const Spacer(),

            // Create Task Button
            ElevatedButton(
              onPressed: _createTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2E5C),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "ASSIGN TASK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}