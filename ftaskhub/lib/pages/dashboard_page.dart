import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/navigation_helper.dart';
import '../auth/login_page.dart';
import 'create_group_page.dart';
import 'groups_page.dart';
import 'video_conference_page.dart';
import 'create_task_page.dart';
import 'taskmanage.dart';
import 'notification_page.dart';
import 'profile_page.dart';


import '../services/firestore_service.dart';

// ✅ widgets utils
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_bottom_nav.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Color primaryBlue = const Color(0xFF0A2E5C);
  final FirestoreService _fs = FirestoreService();

  int _selectedIndex = 0;

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName {
    final name = _user?.displayName;
    if (name != null && name.trim().isNotEmpty) return name;

    final email = _user?.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;

    return 'User';
  }

  String get _subtitle => _user?.email ?? '';

  ImageProvider _profileImageProvider() {
    final url = _user?.photoURL;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return const AssetImage('assets/profile.jpg');
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        navigateWithFade(context, const GroupsPage());
        break;
      case 1:
        _joinVideoConference();
        break;
      case 2:
        _showCreateBottomSheet();
        break;
      case 3:
        navigateWithFade(context, const ProfilePage());
        break;
    }
  }

  Future<void> _logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    navigateReplacementWithFade(context, const LoginPage());
  }

  Future<bool> _ensureHasGroupOrGoCreate() async {
    final groups = await _fs.streamMyGroups().first;

    if (!mounted) return false;

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu belum punya group. Buat group dulu ya.'),
        ),
      );
      navigateWithFade(context, const CreateGroupPage());
      return false;
    }

    return true;
  }

  // ✅ helper: buka CreateTaskPage (pilih group dulu kalau lebih dari 1)
  Future<void> _openCreateTaskPage() async {
    final groups = await _fs.streamMyGroups().first;
    if (!mounted) return;

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu belum punya group. Buat group dulu ya.'),
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

  // ==========================
  // VIDEO CONF
  // ==========================
  // ==========================
  // VIDEO CONF
  // ==========================
  Future<void> _joinVideoConference() async {
    // 1. Ambil list groups dari Firestore
    final groups = await _fs.streamMyGroups().first;

    if (!mounted) return;

    // A. Jika tidak punya group
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu belum punya group. Buat group dulu ya.'),
        ),
      );
      navigateWithFade(context, const CreateGroupPage());
      return;
    }

    // B. Jika hanya 1 group -> langsung join
    if (groups.length == 1) {
      final g = groups.first;
      final gid = g['id'] as String;
      final gName = (g['name'] ?? 'Group Meeting') as String;
      
      _launchVideoConference(gid, gName);
      return;
    }

    // C. Jika > 1 group -> pilih group
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Group untuk Meeting'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final g = groups[index];
                final gid = g['id'] as String;
                final gName = (g['name'] ?? 'Unnamed Group') as String;

                return ListTile(
                  leading: const Icon(Icons.group, color: Color(0xFF0A2E5C)),
                  title: Text(gName),
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchVideoConference(gid, gName);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _launchVideoConference(String meetingId, String meetingName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoConferencePage(
          meetingId: meetingId,
          meetingName: meetingName,
        ),
      ),
    );
  }

  // ==========================
  // CREATE: GROUP / TASK
  // ==========================
  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 220,
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
              leading: const Icon(Icons.groups, color: Color(0xFF0A2E5C)),
              title: const Text('Create Group'),
              subtitle: const Text('Buat kelompok baru'),
              onTap: () {
                Navigator.pop(context);
                navigateWithFade(context, const CreateGroupPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_task, color: Color(0xFF0A2E5C)),
              title: const Text('Create Task'),
              subtitle: const Text('Buat tugas untuk anggota kelompok'),
              onTap: () async {
                Navigator.pop(context);

                final hasGroup = await _ensureHasGroupOrGoCreate();
                if (!hasGroup) return;

                await _openCreateTaskPage();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            DashboardHeader(
              displayName: _displayName,
              subtitle: _subtitle,
              profileImage: _profileImageProvider(),
              onTapProfile: () => _showProfileOptions(context),

              // ✅ badge ambil dari firestore (dashboard_header.dart butuh streamUnreadNotificationCount)
              firestoreService: _fs,

              // ✅ buka halaman notifikasi
              onTapNotifications: () =>
                  navigateWithFade(context, const NotificationPage()),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    _buildStatsCardsFirestore(),
                    _buildQuickActions(),
                    _buildGroupsPreviewFirestore(),
                    _buildRecentTasksFirestore(),
                    _buildCalendarPreview(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        primaryBlue: primaryBlue,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // ==========================
  // STATS (FIRESTORE)
  // ==========================
  Widget _buildStatsCardsFirestore() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fs.streamMyGroups(),
      builder: (context, groupSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _fs.streamMyAssignedTasks(),
          builder: (context, taskSnap) {
            final groups = groupSnap.data ?? [];
            final tasks = taskSnap.data ?? [];
            final doneCount = tasks.where((t) => t['status'] == 'done').length;

            return Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Groups',
                      value: groups.length.toString(),
                      icon: Icons.groups,
                      color: Colors.blue[600]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Tasks',
                      value: tasks.length.toString(),
                      icon: Icons.task,
                      color: Colors.orange[600]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Done',
                      value: doneCount.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green[600]!,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

  // ==========================
  // QUICK ACTIONS
  // ==========================
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
            'Quick Actions',
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
                label: 'New Task',
                color: Colors.blue[600]!,
                onTap: () async {
                  final hasGroup = await _ensureHasGroupOrGoCreate();
                  if (!hasGroup) return;
                  await _openCreateTaskPage();
                },
              ),
              _buildQuickAction(
                icon: Icons.groups,
                label: 'New Group',
                color: Colors.green[600]!,
                onTap: () => navigateWithFade(context, const CreateGroupPage()),
              ),
              _buildQuickAction(
                icon: Icons.list_alt,
                label: 'My Tasks',
                color: Colors.orange[600]!,
                onTap: () => navigateWithFade(context, const MustToDoPage()),
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  // ==========================
  // GROUPS PREVIEW (FIRESTORE)
  // ==========================
  Widget _buildGroupsPreviewFirestore() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fs.streamMyGroups(),
      builder: (context, snapshot) {
        final groups = (snapshot.data ?? []).take(3).toList();

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
                    'Your Groups',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0A2E5C),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        navigateWithFade(context, const GroupsPage()),
                    child: const Text(
                      'See All',
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
                      'No groups yet. Create your first group!',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                )
              else
                Column(
                  children: groups.map((g) {
                    final name = (g['name'] ?? 'Unnamed') as String;
                    final members = (g['memberIds'] is List)
                        ? (g['memberIds'] as List)
                        : <dynamic>[];

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
                                  name,
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
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==========================
  // TASK PREVIEW (FIRESTORE) ✅ sort + filter deadline
  // ==========================
  Widget _buildRecentTasksFirestore() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fs.streamMyAssignedTasks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _simpleCard(
            title: 'Your Tasks',
            child: Text(
              'Gagal memuat tasks:\n${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _simpleCard(
            title: 'Your Tasks',
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final allTasks = snapshot.data ?? [];

        // Sort deadline asc
        allTasks.sort((a, b) {
          final da = a['deadline'];
          final db = b['deadline'];

          DateTime? dta;
          DateTime? dtb;

          if (da is Timestamp) dta = da.toDate();
          if (db is Timestamp) dtb = db.toDate();

          if (dta == null && dtb == null) return 0;
          if (dta == null) return 1;
          if (dtb == null) return -1;
          return dta.compareTo(dtb);
        });

        // ambil 3 task terdekat yang belum done/cancelled
        final tasks = allTasks
            .where((t) => (t['status'] ?? 'todo') != 'done')
            .where((t) => (t['status'] ?? 'todo') != 'cancelled')
            .take(3)
            .toList();

        return _simpleCard(
          title: 'Your Tasks',
          trailing: TextButton(
            onPressed: () => navigateWithFade(context, const MustToDoPage()),
            child: const Text(
              'See All',
              style: TextStyle(color: Color(0xFF0A2E5C)),
            ),
          ),
          child: tasks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No tasks assigned to you yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : Column(
                  children: tasks.map((t) {
                    final title = (t['title'] ?? '-') as String;
                    final status = (t['status'] ?? 'todo') as String;
                    final progress = (t['progress'] ?? 0) as int;

                    DateTime? deadline;
                    final d = t['deadline'];
                    if (d is Timestamp) deadline = d.toDate();

                    final statusColor = _statusColor(status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.06),
                        border: Border.all(color: statusColor, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _statusIcon(status),
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
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (deadline != null)
                                  Text(
                                    'Due: ${_formatDate(deadline)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '$progress%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  // ==========================
  // UPCOMING DEADLINES ✅ from Firestore
  // ==========================
  Widget _buildCalendarPreview() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fs.streamMyAssignedTasks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _simpleCard(
            title: 'Upcoming Deadlines',
            child: Text(
              'Gagal memuat deadlines:\n${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _simpleCard(
            title: 'Upcoming Deadlines',
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final tasks = snapshot.data ?? [];
        final now = DateTime.now();

        final upcoming = tasks.where((t) {
          final status = (t['status'] ?? 'todo') as String;
          if (status == 'done' || status == 'cancelled') return false;

          final d = t['deadline'];
          if (d is! Timestamp) return false;

          final dt = d.toDate();
          return !dt.isBefore(now);
        }).toList();

        upcoming.sort((a, b) {
          final da = (a['deadline'] as Timestamp).toDate();
          final db = (b['deadline'] as Timestamp).toDate();
          return da.compareTo(db);
        });

        final top = upcoming.take(5).toList();

        return _simpleCard(
          title: 'Upcoming Deadlines',
          child: top.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Tidak ada deadline terdekat.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : Column(
                  children: top.map((t) {
                    final title = (t['title'] ?? '-') as String;
                    final status = (t['status'] ?? 'todo') as String;
                    final progress = (t['progress'] ?? 0) as int;

                    final deadline = (t['deadline'] as Timestamp).toDate();
                    final daysLeft = deadline.difference(now).inDays;

                    final badgeColor = daysLeft <= 1
                        ? Colors.red
                        : (daysLeft <= 3 ? Colors.orange : Colors.green);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              daysLeft <= 0 ? 'Today' : '${daysLeft}d',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                Text(
                                  'Due: ${_formatDate(deadline)} • $status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$progress%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A2E5C),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  // ==========================
  // SIMPLE CARD helper
  // ==========================
  Widget _simpleCard({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
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
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0A2E5C),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ==========================
  // PROFILE OPTIONS
  // ==========================
  void _showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 240,
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
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(backgroundImage: _profileImageProvider()),
              title: Text(
                _displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_subtitle),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================
  // SETTINGS
  // ==========================


  // ==========================
  // STATUS UI
  // ==========================
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'todo':
        return Icons.radio_button_unchecked;
      case 'inProgress':
        return Icons.hourglass_bottom;
      case 'done':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
