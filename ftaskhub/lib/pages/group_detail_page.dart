import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/task_hub_service.dart';
import 'task_detail_page.dart';
import 'chat_page.dart';
import 'assign_task_page.dart';

class GroupDetailPage extends StatefulWidget {
  final Group group;
  final User currentUser;

  const GroupDetailPage({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TaskHubService _taskHubService = TaskHubService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _taskHubService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = _taskHubService.getGroupMembers(widget.group.id);
    final groupProgress = _taskHubService.getGroupProgress(widget.group.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0A2E5C),
      appBar: AppBar(
        title: Text(
          widget.group.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A2E5C),
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'chat') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      groupTitle: widget.group.name,
                      members: members.map((user) => user.name).toList(),
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'chat',
                child: Text('Open Chat'),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Group Settings'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Group Header with Progress
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2E5C),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.group.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A2E5C),
                            ),
                          ),
                          Text(
                            '${members.length} members',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.group.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                // Progress section
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress: ${groupProgress.round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A2E5C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: groupProgress / 100,
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF0A2E5C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Stats about tasks
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _getGroupStats(widget.group.id),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_taskHubService.getTasksByGroup(widget.group.id).length} tasks',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Task status breakdown
                _buildTaskStatusBreakdown(widget.group.id),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tabs for Tasks, Members, and Chat
          Container(
            width: double.infinity,
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF0A2E5C),
              labelColor: const Color(0xFF0A2E5C),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Tasks'),
                Tab(text: 'Members'),
                Tab(text: 'Chat'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                _buildMembersTab(members),
                _buildChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGroupStats(String groupId) {
    final tasks = _taskHubService.getTasksByGroup(groupId);
    if (tasks.isEmpty) return "No tasks";
    
    int todo = 0;
    int inProgress = 0;
    int done = 0;
    
    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.todo:
          todo++;
          break;
        case TaskStatus.inProgress:
          inProgress++;
          break;
        case TaskStatus.done:
          done++;
          break;
        case TaskStatus.cancelled:
          break; // Don't count cancelled tasks in the main counts
      }
    }
    
    return "$todo todo, $inProgress in progress, $done done";
  }

  Widget _buildTaskStatusBreakdown(String groupId) {
    final tasks = _taskHubService.getTasksByGroup(groupId);
    if (tasks.isEmpty) return Container();

    int todo = 0;
    int inProgress = 0;
    int done = 0;
    int cancelled = 0;
    
    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.todo:
          todo++;
          break;
        case TaskStatus.inProgress:
          inProgress++;
          break;
        case TaskStatus.done:
          done++;
          break;
        case TaskStatus.cancelled:
          cancelled++;
          break;
      }
    }

    final total = tasks.length;
    if (total == 0) return Container();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildStatusItem(
            'To Do', 
            todo, 
            total, 
            Colors.grey, 
            Icons.radio_button_unchecked
          ),
          const SizedBox(width: 8),
          _buildStatusItem(
            'In Progress', 
            inProgress, 
            total, 
            Colors.orange, 
            Icons.hourglass_bottom
          ),
          const SizedBox(width: 8),
          _buildStatusItem(
            'Done', 
            done, 
            total, 
            Colors.green, 
            Icons.check_circle
          ),
          if (cancelled > 0) ...[
            const SizedBox(width: 8),
            _buildStatusItem(
              'Cancelled', 
              cancelled, 
              total, 
              Colors.red, 
              Icons.cancel
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, int total, Color color, IconData icon) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    final tasks = _taskHubService.getTasksByGroup(widget.group.id);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.task_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assign your first task to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssignTaskPage(
                      group: widget.group,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2E5C),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text(
                "Create Task",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Refresh the page
      },
      child: Column(
        children: [
          // Add task button at the top
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssignTaskPage(
                      group: widget.group,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2E5C),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Assign New Task",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final assignee = _taskHubService.getUserById(task.assigneeId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(task.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getStatusIcon(task.status),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned to: ${assignee?.name ?? "Unknown"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${task.progress}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A2E5C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: task.progress / 100,
                            minHeight: 4,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF0A2E5C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailPage(
                            task: task,
                            group: widget.group,
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(List<User> members) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: member.avatarUrl.isNotEmpty
                    ? AssetImage(member.avatarUrl) as ImageProvider
                    : null,
                backgroundColor: const Color(0xFF0A2E5C),
                child: member.avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              title: Text(member.name),
              subtitle: Text(member.email),
              trailing: widget.currentUser.id == widget.group.creatorId
                  ? PopupMenuButton<String>(
                      onSelected: (String result) {
                        // Handle member actions
                      },
                      itemBuilder: (BuildContext context) => 
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'remove',
                          child: Text('Remove from group'),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatTab() {
    return ChatPage(
      groupTitle: widget.group.name,
      members: _taskHubService.getGroupMembers(widget.group.id)
          .map((user) => user.name)
          .toList(),
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

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.hourglass_bottom;
      case TaskStatus.done:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }
}