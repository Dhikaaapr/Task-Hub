import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart';
import 'create_group_page.dart';
import '../auth/login_page.dart';
import 'groups_page.dart'; // Import the new groups page
import 'calendar_integration_page.dart';
import 'video_conference_page.dart'; // Import video conference page
import '../models/task_hub_service.dart';
import '../models/group.dart';
import '../models/task.dart'; // Import Task model to use TaskStatus

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Color primaryBlue = const Color(0xFF0A2E5C);
  final TaskHubService _taskHubService = TaskHubService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _taskHubService.initialize();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        navigateWithFade(context, const GroupsPage()); // Navigate to groups page
        break;
      case 1:
        _joinVideoConference();
        break;
      case 2:
        navigateWithFade(context, const CreateGroupPage());
        break;
      case 3:
        navigateWithFade(context, const GroupsPage()); // Navigate to groups page
        break;
      case 4:
        _showSettingsBottomSheet();
        break;
    }
  }

  void _joinVideoConference() {
    // In a real app, this would integrate with a video conference service like Jitsi, Zoom, etc.
    // For now, we'll show a simple alert
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Join Video Conference"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select a meeting to join:"),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.video_call),
                title: const Text("Team Standup"),
                subtitle: const Text("Today, 10:00 AM"),
                onTap: () {
                  Navigator.of(context).pop();
                  _launchVideoConference("standup_meeting");
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_call),
                title: const Text("Project Review"),
                subtitle: const Text("Today, 2:00 PM"),
                onTap: () {
                  Navigator.of(context).pop();
                  _launchVideoConference("review_meeting");
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _launchVideoConference(String meetingId) {
    // Navigate to the video conference page
    Navigator.of(context).pop(); // Close the dialog first

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoConferencePage(
          meetingId: meetingId,
          meetingName: meetingId == "standup_meeting" ? "Team Standup" : "Project Review",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header profile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProfileOptions(context),
                    child: const CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/profile.jpg'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Andhika Presha Saputra",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Paramadina University",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    // Quick Stats Cards
                    _buildStatsCards(),

                    // Quick Actions
                    _buildQuickActions(),

                    // Groups Preview
                    _buildGroupsPreview(),

                    // Recent Tasks
                    _buildRecentTasks(),

                    // Calendar Preview
                    _buildCalendarPreview(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: primaryBlue,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: primaryBlue,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.groups),
              label: 'GROUPS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_call),
              label: 'MEET',
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.add, color: Color(0xFF0A2E5C)),
              ),
              label: 'CREATE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups),
              label: 'GROUPS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'MORE',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    // Get all data for stats
    final groups = _taskHubService.getGroups();
    final tasks = _taskHubService.getTasksByUser('current_user_id');
    final completedTasks = tasks.where((task) => task.status == TaskStatus.done).length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: "Groups",
              value: groups.length.toString(),
              icon: Icons.groups,
              color: Colors.blue[600]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Tasks",
              value: tasks.length.toString(),
              icon: Icons.task,
              color: Colors.orange[600]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Done",
              value: completedTasks.toString(),
              icon: Icons.check_circle,
              color: Colors.green[600]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2E5C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0A2E5C),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAction(
                icon: Icons.add_task,
                label: "New Task",
                color: Colors.blue[600]!,
                onTap: () => navigateWithFade(context, const CreateGroupPage()),
              ),
              _buildQuickAction(
                icon: Icons.groups,
                label: "New Group",
                color: Colors.green[600]!,
                onTap: () => navigateWithFade(context, const GroupsPage()),
              ),
              _buildQuickAction(
                icon: Icons.calendar_today,
                label: "Calendar",
                color: Colors.orange[600]!,
                onTap: () {
                  final currentUser = _taskHubService.getUserById('current_user_id');
                  if (currentUser != null) {
                    final groups = _taskHubService.getGroups();
                    if (groups.isNotEmpty) {
                      navigateWithFade(context, CalendarIntegrationPage(group: groups.first));
                    } else {
                      final tempGroup = Group(
                        id: 'dashboard_calendar',
                        name: 'All Tasks',
                        description: 'All your tasks across groups',
                        memberIds: [currentUser.id],
                        creatorId: currentUser.id,
                        createdAt: DateTime.now(),
                      );
                      navigateWithFade(context, CalendarIntegrationPage(group: tempGroup));
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsPreview() {
    final groups = _taskHubService.getGroups().take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Groups",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0A2E5C),
                ),
              ),
              TextButton(
                onPressed: () => navigateWithFade(context, const GroupsPage()),
                child: const Text(
                  "See All",
                  style: TextStyle(color: Color(0xFF0A2E5C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "No groups yet. Create your first group!",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Column(
              children: groups.map((group) {
                final members = _taskHubService.getGroupMembers(group.id);
                final progress = _taskHubService.getGroupProgress(group.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2E5C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${progress.round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF0A2E5C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0A2E5C),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildRecentTasks() {
    final tasks = _taskHubService.getTasksByUser('current_user_id').take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Tasks",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0A2E5C),
            ),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "No tasks assigned to you yet.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Column(
              children: tasks.map((task) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withValues(alpha: 0.05),
                    border: Border.all(
                      color: _getStatusColor(task.status),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getStatusIcon(task.status),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (task.dueDate != null)
                              Text(
                                'Due: ${_formatDate(task.dueDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${task.progress}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getStatusColor(task.status),
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

  Widget _buildCalendarPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upcoming Deadlines",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0A2E5C),
            ),
          ),
          const SizedBox(height: 12),
          // Show upcoming tasks in calendar view
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Calendar preview would show upcoming tasks",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }


  // ==== WIDGET LAIN ====

  void _showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                navigateReplacementWithFade(context, const LoginPage());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Color(0xFF0A2E5C)),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFF0A2E5C)),
              title: const Text("Notifications"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF0A2E5C)),
              title: const Text("Help & Support"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

}
