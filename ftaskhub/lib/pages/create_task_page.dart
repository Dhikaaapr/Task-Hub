import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

class CreateTaskPage extends StatefulWidget {
  final String groupId; // wajib: create task harus dalam group
  const CreateTaskPage({super.key, required this.groupId});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final FirestoreService _fs = FirestoreService();

  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

  bool _loading = false;

  // group data
  Map<String, dynamic>? _groupData;
  List<String> _memberIds = [];

  // profiles cache: uid -> {name,email,photoUrl}
  final Map<String, Map<String, dynamic>> _profiles = {};

  String? _selectedAssigneeId;

  // optional priority (kalau kamu mau simpan)
  String _priority = 'medium'; // low | medium | high | urgent

  @override
  void initState() {
    super.initState();
    _loadGroupAndMembers();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupAndMembers() async {
    setState(() => _loading = true);
    try {
      final g = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (!g.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Group tidak ditemukan.")));
        Navigator.pop(context);
        return;
      }

      _groupData = g.data() ?? {};
      _memberIds = (_groupData?['memberIds'] is List)
          ? (_groupData?['memberIds'] as List).map((e) => e.toString()).toList()
          : <String>[];

      if (_memberIds.isNotEmpty) {
        _selectedAssigneeId = _memberIds.first;
      }

      // fetch profiles users
      for (final uid in _memberIds) {
        if (_profiles.containsKey(uid)) continue;

        final u = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (u.exists) {
          _profiles[uid] = u.data() ?? {};
        } else {
          _profiles[uid] = {
            'uid': uid,
            'name': 'Unknown',
            'email': '',
            'photoUrl': '',
          };
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal load group: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _composeDeadline(DateTime date, TimeOfDay? time) {
    // Kalau user belum pilih jam, set default 23:59 biar deadline “hari itu”
    final t = time ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
  }

  Future<void> _submitTask() async {
    final title = _taskNameController.text.trim();
    final desc = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Task name wajib diisi")));
      return;
    }

    if (_selectedAssigneeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilih assignee dulu")));
      return;
    }

    final deadline = _composeDeadline(_selectedDate, _selectedTime);

    setState(() => _loading = true);
    try {
      // create task utama (sesuai service kamu)
      await _fs.createTask(
        groupId: widget.groupId,
        title: title,
        description: desc,
        assigneeId: _selectedAssigneeId!,
        deadline: deadline,
      );

      // OPTIONAL: kalau kamu mau simpan priority juga,
      // kamu bisa update last created doc, tapi karena createTask pakai add()
      // kita lebih rapi: ubah FirestoreService.createTask agar menerima priority
      // atau return docId.
      //
      // Untuk sekarang: biarkan saja tidak menyimpan priority,
      // atau kamu upgrade service (aku kasih contoh di bawah).

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Task berhasil dibuat")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal buat task: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _assigneeLabel(String uid) {
    final p = _profiles[uid] ?? {};
    final name = (p['name'] ?? '').toString();
    final email = (p['email'] ?? '').toString();

    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email;
    return uid;
  }

  ImageProvider _assigneeAvatar(String uid) {
    final p = _profiles[uid] ?? {};
    final photoUrl = (p['photoUrl'] ?? '').toString();
    if (photoUrl.isNotEmpty) return NetworkImage(photoUrl);
    return const AssetImage('assets/profile.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final groupName = (_groupData?['name'] ?? 'Create Task').toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          groupName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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

                  const SizedBox(height: 16),

                  // Assignee dropdown (memberIds)
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedAssigneeId,
                        hint: const Text('Select a member'),
                        items: _memberIds.map((uid) {
                          return DropdownMenuItem(
                            value: uid,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: _assigneeAvatar(uid),
                                  backgroundColor: const Color(0xFF0A2E5C),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _assigneeLabel(uid),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedAssigneeId = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date picker (simple)
                  const Text(
                    "Deadline Date",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate.isBefore(now)
                            ? now
                            : _selectedDate,
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Time picker
                  Row(
                    children: [
                      const Text(
                        "Deadline Time:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                          );
                          if (t != null) setState(() => _selectedTime = t);
                        },
                        child: Text(
                          _selectedTime == null
                              ? "Select Time (optional)"
                              : _selectedTime!.format(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Priority (optional string)
                  const Text(
                    "Priority",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: const ['low', 'medium', 'high', 'urgent']
                        .map((p) {
                          return p;
                        })
                        .toList()
                        .map((p) {
                          return ChoiceChip(label: Text(p), selected: false);
                        })
                        .toList(),
                  ),

                  // Supaya ChoiceChip bisa dipakai (karena di atas const),
                  // kita render yang “real” di bawah:
                  Wrap(
                    spacing: 8,
                    children: ['low', 'medium', 'high', 'urgent'].map((p) {
                      return ChoiceChip(
                        label: Text(p),
                        selected: _priority == p,
                        onSelected: (selected) {
                          if (selected) setState(() => _priority = p);
                        },
                      );
                    }).toList(),
                  ),

                  const Spacer(),

                  ElevatedButton(
                    onPressed: _loading ? null : _submitTask,
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
}
