import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';

import '../services/firestore_service.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with TickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();

  late TabController _tabController;

  // cache member profiles
  final Map<String, Map<String, dynamic>> _memberProfiles = {};
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _prefetchMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =========================
  // MEMBERS: fetch profile dari /users/{uid}
  // =========================
  Future<void> _prefetchMembers() async {
    if (_loadingMembers) return;
    setState(() => _loadingMembers = true);

    try {
      final groupSnap = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (!groupSnap.exists) return;

      final data = groupSnap.data() ?? {};
      final memberIds = (data['memberIds'] is List)
          ? (data['memberIds'] as List).map((e) => e.toString()).toList()
          : <String>[];

      // fetch per uid (aman untuk member >10)
      for (final uid in memberIds) {
        if (_memberProfiles.containsKey(uid)) continue;

        final u = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (u.exists) {
          _memberProfiles[uid] = u.data() ?? {};
        } else {
          _memberProfiles[uid] = {
            'uid': uid,
            'name': 'Unknown',
            'email': '',
            'photoUrl': '',
          };
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  // =========================
  // CREATE TASK DIALOG (Firestore)
  // =========================
  Future<void> _showCreateTaskDialog(Map<String, dynamic> groupData) async {
    final memberIds = (groupData['memberIds'] is List)
        ? (groupData['memberIds'] as List).map((e) => e.toString()).toList()
        : <String>[];

    if (memberIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Member group kosong.")));
      return;
    }

    // pastikan profiles sudah ke-fetch
    await _prefetchMembers();
    if (!mounted) return;

    String selectedAssigneeId = memberIds.first;

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? deadline;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            title: const Text("Create Task"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedAssigneeId,
                    decoration: const InputDecoration(
                      labelText: "Assignee",
                      border: OutlineInputBorder(),
                    ),
                    items: memberIds.map((uid) {
                      final p = _memberProfiles[uid] ?? {};
                      final name = (p['name'] ?? '').toString();
                      final email = (p['email'] ?? '').toString();
                      final label = name.isNotEmpty
                          ? name
                          : (email.isNotEmpty ? email : uid);
                      return DropdownMenuItem(value: uid, child: Text(label));
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setStateDialog(() => selectedAssigneeId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Description (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            deadline == null
                                ? "Pick Deadline"
                                : "Deadline: ${_formatDate(deadline!)}",
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: now.add(const Duration(days: 1)),
                              firstDate: now,
                              lastDate: DateTime(now.year + 5),
                            );
                            if (picked != null) {
                              setStateDialog(() => deadline = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2E5C),
                ),
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty || deadline == null) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text("Title dan Deadline wajib diisi."),
                      ),
                    );
                    return;
                  }

                  try {
                    await _fs.createTask(
                      groupId: widget.groupId,
                      title: title,
                      description: descCtrl.text.trim(),
                      assigneeId: selectedAssigneeId,
                      deadline: deadline!,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task berhasil dibuat.")),
                    );
                  } catch (e) {
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text("Gagal buat task: $e")),
                    );
                  }
                },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );

    titleCtrl.dispose();
    descCtrl.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2E5C),
      appBar: AppBar(
        title: const Text(
          'Group Detail',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A2E5C),
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'refresh') _prefetchMembers();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh Members')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .snapshots(),
        builder: (context, groupSnap) {
          if (groupSnap.hasError) {
            return _buildError("Gagal memuat group: ${groupSnap.error}");
          }
          if (!groupSnap.hasData) {
            return _buildLoading();
          }
          if (!groupSnap.data!.exists) {
            return _buildError("Group tidak ditemukan.");
          }

          final groupData = groupSnap.data!.data() ?? {};
          final groupName = (groupData['name'] ?? 'Unnamed') as String;
          final description = (groupData['description'] ?? '') as String;

          final memberIds = (groupData['memberIds'] is List)
              ? (groupData['memberIds'] as List)
                    .map((e) => e.toString())
                    .toList()
              : <String>[];

          return Column(
            children: [
              // Header
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
                                groupName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A2E5C),
                                ),
                              ),
                              Text(
                                '${memberIds.length} members',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_task,
                            color: Color(0xFF0A2E5C),
                          ),
                          onPressed: () => _showCreateTaskDialog(groupData),
                          tooltip: 'Create Task',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description.isEmpty ? 'No description' : description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),

                    // Stats & progress dari tasks
                    _buildGroupProgress(widget.groupId),
                  ],
                ),
              ),

              // Tabs
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
                    _buildTasksTab(widget.groupId),
                    _buildMembersTab(memberIds),
                    _buildChatTabPlaceholder(groupName),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupProgress(String groupId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        final total = docs.length;
        final done = docs.where((d) => (d.data()['status'] == 'done')).length;

        final progress = total == 0 ? 0.0 : (done / total) * 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress: ${progress.round()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2E5C),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (done / total),
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF0A2E5C),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              total == 0 ? "No tasks" : "$done done / $total tasks",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // TASKS TAB
  // =========================
  Widget _buildTasksTab(String groupId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .orderBy('deadline')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _buildError("Gagal memuat tasks: ${snap.error}");
        }
        if (!snap.hasData) {
          return _buildLoading();
        }

        final tasks = snap.data!.docs;
        if (tasks.isEmpty) {
          return _emptyTasks();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final doc = tasks[index];
            final t = doc.data();

            final title = (t['title'] ?? '-') as String;
            final status = (t['status'] ?? 'todo') as String;
            final progress = (t['progress'] ?? 0) as int;

            DateTime? deadline;
            final d = t['deadline'];
            if (d is Timestamp) deadline = d.toDate();

            final assigneeId = (t['assigneeId'] ?? '') as String;
            final assigneeProfile = _memberProfiles[assigneeId] ?? {};
            final assigneeName = (assigneeProfile['name'] ?? '').toString();
            final assigneeEmail = (assigneeProfile['email'] ?? '').toString();
            final assigneeLabel = assigneeName.isNotEmpty
                ? assigneeName
                : (assigneeEmail.isNotEmpty ? assigneeEmail : assigneeId);

            final statusColor = _statusColor(status);
            final statusIcon = _statusIcon(status);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 20),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Assigned to: $assigneeLabel',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (deadline != null)
                      Text(
                        'Deadline: ${_formatDate(deadline)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$progress%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2E5C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 4,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0A2E5C),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // kamu bisa bikin TaskDetail Firestore nanti
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Task: $title')));
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyTasks() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No tasks yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first task to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // =========================
  // MEMBERS TAB
  // =========================
  Widget _buildMembersTab(List<String> memberIds) {
    if (_loadingMembers) {
      return _buildLoading();
    }

    return RefreshIndicator(
      onRefresh: () async => _prefetchMembers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: memberIds.length,
        itemBuilder: (context, index) {
          final uid = memberIds[index];
          final p = _memberProfiles[uid] ?? {};

          final name = (p['name'] ?? 'Unknown').toString();
          final email = (p['email'] ?? '').toString();
          final photoUrl = (p['photoUrl'] ?? '').toString();

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : const AssetImage('assets/profile.jpg') as ImageProvider,
                backgroundColor: const Color(0xFF0A2E5C),
              ),
              title: Text(name),
              subtitle: Text(email),
            ),
          );
        },
      ),
    );
  }

  // =========================
  // CHAT TAB PLACEHOLDER
  // =========================
  Widget _buildChatTabPlaceholder(String groupName) {
    return ChatPage(groupId: widget.groupId, groupTitle: groupName);
  }

  // =========================
  // HELPERS
  // =========================
  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
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
    return "${date.day}/${date.month}/${date.year}";
  }
}
