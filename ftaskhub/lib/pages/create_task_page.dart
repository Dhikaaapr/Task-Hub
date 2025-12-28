import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task_hub_service.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/group.dart';

class CreateTaskPage extends StatefulWidget {
  final Group? group;  // Optional group parameter
  final User? currentUser;  // Optional current user parameter

  const CreateTaskPage({super.key, this.group, this.currentUser});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final TaskHubService _taskHubService = TaskHubService();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  String? selectedAssigneeId;
  TaskPriority selectedPriority = TaskPriority.medium;
  TaskStatus selectedStatus = TaskStatus.todo;

  @override
  void initState() {
    super.initState();
    _taskHubService.initialize();
  }

  void _submitTask() {
    if (_taskNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task name is required")),
      );
      return;
    }

    // If we're creating from a group, we need an assignee
    if (widget.group != null && selectedAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an assignee")),
      );
      return;
    }

    final groupId = widget.group?.id ?? 'general'; // Default to 'general' if no group specified
    final assigneeId = selectedAssigneeId ?? (widget.currentUser?.id ?? 'current_user_id');
    final createdBy = widget.currentUser?.id ?? 'current_user_id';

    final task = _taskHubService.createTask(
      title: _taskNameController.text,
      description: _descriptionController.text,
      groupId: groupId,
      assigneeId: assigneeId,
      createdBy: createdBy,
      dueDate: selectedDate,
    );

    // Update task with selected priority and status
    final updatedTask = task.copyWith(
      priority: selectedPriority,
      status: selectedStatus,
    );
    _taskHubService.updateTask(updatedTask);

    Navigator.pop(context, updatedTask);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Task created successfully"),
        backgroundColor: Color(0xFF0A2E5C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<User> members = [];

    // Get members if we're in a group context
    if (widget.group != null) {
      members = _taskHubService.getGroupMembers(widget.group!.id);
    } else {
      // If not in a group, just add the current user
      if (widget.currentUser != null) {
        members = [widget.currentUser!];
      } else {
        final currentUser = _taskHubService.getUserById('current_user_id');
        if (currentUser != null) members = [currentUser];
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Create Task", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(
                labelText: "Task Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Show assignee selection only if we're in a group context
            if (widget.group != null) ...[
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
                  value: selectedAssigneeId,
                  hint: const Text('Select a member'),
                  underline: Container(),
                  items: members.map((user) {
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
                      selectedAssigneeId = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text("DATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TableCalendar(
                focusedDay: selectedDate,
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2035),
                selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                onDaySelected: (day, _) => setState(() => selectedDate = day),
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Color(0xFF0A2E5C),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF0A2E5C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Text(
                  "Time:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 15),
                OutlinedButton(
                  child: Text(
                    selectedTime == null
                        ? "Select Time"
                        : selectedTime!.format(context),
                  ),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (time != null) setState(() => selectedTime = time);
                  },
                ),
              ],
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
                  selected: selectedPriority == priority,
                  selectedColor: _getPriorityColor(priority),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) selectedPriority = priority;
                    });
                  },
                );
              }).toList(),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _submitTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2E5C),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "CREATE TASK",
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
