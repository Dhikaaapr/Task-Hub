import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String groupTitle;

  /// Optional (kalau kamu mau fallback display cepat)
  final List<String>? members;

  const ChatPage({
    super.key,
    required this.groupId,
    required this.groupTitle,
    this.members,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final TextEditingController messageController = TextEditingController();
  bool _isSending = false;

  User? get _user => _auth.currentUser;

  String get _senderName {
    final u = _user;
    if (u == null) return 'Unknown';
    final name = (u.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    final email = (u.email ?? '').trim();
    if (email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  String get _senderEmail => (_user?.email ?? '').trim();

  DocumentReference<Map<String, dynamic>> get _groupDoc =>
      _db.collection('groups').doc(widget.groupId);

  CollectionReference<Map<String, dynamic>> get _messagesCol =>
      _groupDoc.collection('messages');

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _db.collection('tasks');

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  // =========================
  // SEND MESSAGE
  // =========================
  Future<void> _sendMessage() async {
    final u = _user;
    if (u == null) return;

    final text = messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _messagesCol.add({
        'type': 'text',
        'text': text,
        'senderId': u.uid,
        'senderName': _senderName,
        'senderEmail': _senderEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal kirim pesan: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // =========================
  // TASKS (FOR PROGRESS UPDATE MENU)
  // =========================
  Stream<List<Map<String, dynamic>>> _streamTasksByGroup() {
    // Jika kamu pakai orderBy('deadline') + where('groupId'),
    // itu BUTUH index. Untuk aman, kita urutkan by createdAt.
    // (Kalau kamu mau tetap deadline, bikin index groupId+deadline)
    return _tasksCol
        .where('groupId', isEqualTo: widget.groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        });
  }

  Future<void> _updateTaskProgressAndNotify({
    required String taskId,
    required String taskTitle,
    required int newProgress,
  }) async {
    final u = _user;
    if (u == null) return;

    String newStatus = 'inProgress';
    if (newProgress <= 0) newStatus = 'todo';
    if (newProgress >= 100) newStatus = 'done';

    try {
      await _tasksCol.doc(taskId).update({
        'progress': newProgress,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _messagesCol.add({
        'type': 'progressUpdate',
        'text': "Updated progress of '$taskTitle' to $newProgress%",
        'taskId': taskId,
        'taskTitle': taskTitle,
        'progress': newProgress,
        'senderId': u.uid,
        'senderName': _senderName,
        'senderEmail': _senderEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal update progress: $e')));
    }
  }

  // =========================
  // MEMBERS
  // =========================
  Stream<List<Map<String, dynamic>>> _streamMembers() async* {
    // ambil memberIds dari groups/{groupId}
    final groupSnapStream = _groupDoc.snapshots();

    await for (final groupSnap in groupSnapStream) {
      final data = groupSnap.data();
      final memberIds = (data?['memberIds'] is List)
          ? List<String>.from(data!['memberIds'] as List)
          : <String>[];

      if (memberIds.isEmpty) {
        // fallback pakai widget.members
        final fallback = (widget.members ?? []).map((name) {
          return {'name': name, 'email': ''};
        }).toList();
        yield fallback;
        continue;
      }

      // users where uid in [...] max 10 per query => chunk
      final results = <Map<String, dynamic>>[];
      final chunks = <List<String>>[];

      for (var i = 0; i < memberIds.length; i += 10) {
        final end = (i + 10 < memberIds.length) ? i + 10 : memberIds.length;
        chunks.add(memberIds.sublist(i, end));
      }

      for (final c in chunks) {
        final snap = await _db
            .collection('users')
            .where('uid', whereIn: c)
            .get();

        for (final d in snap.docs) {
          final u = d.data();
          results.add({
            'uid': u['uid'] ?? d.id,
            'name': (u['name'] ?? '').toString(),
            'email': (u['email'] ?? '').toString(),
            'photoUrl': (u['photoUrl'] ?? '').toString(),
          });
        }
      }

      // Sort biar stabil
      results.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      yield results;
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(widget.groupTitle),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: const Color(0xFF0A2E5C),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'members') {
                _showMembersBottomSheet();
              } else if (result == 'progress') {
                _showProgressUpdatesBottomSheet();
              }
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'members',
                    child: Text('Group Members'),
                  ),
                  PopupMenuItem<String>(
                    value: 'progress',
                    child: Text('Progress Updates'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ====== MESSAGES LIST ======
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesCol
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Gagal memuat chat:\n${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Belum ada chat. Mulai kirim pesan!'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final m = docs[index].data();

                    final type = (m['type'] ?? 'text').toString();
                    final text = (m['text'] ?? '').toString();
                    final senderId = (m['senderId'] ?? '').toString();
                    final senderName = (m['senderName'] ?? 'Unknown')
                        .toString();

                    final isMe = _user != null && senderId == _user!.uid;

                    final createdAt = m['createdAt'];
                    final ts = createdAt is Timestamp
                        ? createdAt.toDate()
                        : null;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _getMessageColor(type, isMe),
                          borderRadius: _getMessageBorderRadius(isMe),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe) ...[
                              Text(
                                senderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getTextColor(isMe, type),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (type == 'progressUpdate') ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Progress Update",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _getTextColor(isMe, type),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              text,
                              style: TextStyle(
                                color: _getTextColor(isMe, type),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ts == null ? '' : _formatTime(ts),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getTimeColor(isMe),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ====== INPUT BAR ======
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                // progress button (ambil task dari firestore)
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _streamTasksByGroup(),
                  builder: (context, snap) {
                    final tasks = snap.data ?? [];
                    return PopupMenuButton<Map<String, dynamic>>(
                      enabled: tasks.isNotEmpty,
                      onSelected: (t) {
                        _showProgressUpdateDialog(
                          taskId: (t['id'] ?? '').toString(),
                          taskTitle: (t['title'] ?? '-').toString(),
                          currentProgress: (t['progress'] is int)
                              ? t['progress'] as int
                              : 0,
                        );
                      },
                      itemBuilder: (context) {
                        return tasks.map((t) {
                          final title = (t['title'] ?? '-').toString();
                          final prog = (t['progress'] is int)
                              ? t['progress'] as int
                              : 0;
                          return PopupMenuItem<Map<String, dynamic>>(
                            value: t,
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$title ($prog%)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tasks.isEmpty
                              ? Colors.grey[100]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          color: tasks.isEmpty
                              ? Colors.grey
                              : const Color(0xFF0A2E5C),
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: TextField(
                    controller: messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[200],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                CircleAvatar(
                  backgroundColor: const Color(0xFF0A2E5C),
                  child: IconButton(
                    icon: Icon(
                      _isSending ? Icons.hourglass_empty : Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HELPERS UI
  // =========================
  Color _getMessageColor(String type, bool isMe) {
    if (type == 'progressUpdate') return Colors.blue[50]!;
    return isMe ? Colors.lightBlueAccent : Colors.white.withValues(alpha: 0.9);
  }

  BorderRadius _getMessageBorderRadius(bool isMe) {
    if (isMe) {
      return const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
    }
    return const BorderRadius.only(
      topLeft: Radius.circular(5),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    );
  }

  Color _getTextColor(bool isMe, String type) {
    if (type == 'progressUpdate') return Colors.blue[800]!;
    return isMe ? Colors.white : Colors.black87;
  }

  Color _getTimeColor(bool isMe) {
    return isMe ? Colors.white70 : Colors.grey[600]!;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    return "${difference.inDays}d ago";
  }

  // =========================
  // BOTTOM SHEETS
  // =========================
  void _showMembersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _streamMembers(),
          builder: (context, snap) {
            final members = snap.data ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Group Members",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Tidak ada member.'),
                  )
                else
                  ...members.map((m) {
                    final name = (m['name'] ?? '').toString().trim();
                    final email = (m['email'] ?? '').toString().trim();
                    final photoUrl = (m['photoUrl'] ?? '').toString().trim();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0A2E5C),
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(name.isEmpty ? 'Unknown' : name),
                      subtitle: email.isEmpty ? null : Text(email),
                    );
                  }),
                const SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showProgressUpdatesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _messagesCol
              .where('type', isEqualTo: 'progressUpdate')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('Gagal: ${snap.error}');
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snap.data?.docs ?? [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Progress Updates",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                if (docs.isEmpty)
                  const Center(child: Text("No progress updates yet"))
                else
                  ...docs.map((d) {
                    final m = d.data();
                    final text = (m['text'] ?? '').toString();
                    final createdAt = m['createdAt'];
                    final ts = createdAt is Timestamp
                        ? createdAt.toDate()
                        : null;

                    return ListTile(
                      leading: const Icon(
                        Icons.trending_up,
                        color: Colors.blue,
                      ),
                      title: Text(text),
                      subtitle: ts == null
                          ? null
                          : Text(
                              _formatTime(ts),
                              style: const TextStyle(fontSize: 12),
                            ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================
  // PROGRESS DIALOG
  // =========================
  void _showProgressUpdateDialog({
    required String taskId,
    required String taskTitle,
    required int currentProgress,
  }) {
    int progressValue = currentProgress.clamp(0, 100);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Update Task Progress'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Updating: $taskTitle',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: progressValue.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '$progressValue%',
                    activeColor: const Color(0xFF0A2E5C),
                    onChanged: (value) {
                      setStateDialog(() => progressValue = value.round());
                    },
                  ),
                  Text(
                    '$progressValue%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _updateTaskProgressAndNotify(
                      taskId: taskId,
                      taskTitle: taskTitle,
                      newProgress: progressValue,
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
