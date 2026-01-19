import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/navigation_helper.dart';
import '../services/firestore_service.dart';
import 'groups_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final FirestoreService _fs = FirestoreService();

  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailSearchController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _myEmail =>
      (FirebaseAuth.instance.currentUser?.email ?? '').trim();

  // selected members by uid
  final List<String> _memberIds = [];

  // cache profile untuk chip: uid -> {name,email,photoUrl}
  final Map<String, Map<String, dynamic>> _memberProfiles = {};

  // hasil search
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();

    // pastikan user ada di selected member
    if (_myUid.isNotEmpty) {
      _memberIds.add(_myUid);
      _memberProfiles[_myUid] = {
        'name': 'You',
        'email': _myEmail,
        'photoUrl': FirebaseAuth.instance.currentUser?.photoURL ?? '',
      };
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _emailSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchByEmail() async {
    final email = _emailSearchController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email untuk mencari user.')),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final found = await _fs.findUsersByEmail(email);

      if (!mounted) return;

      setState(() {
        _searchResults = found;
      });

      if (found.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User tidak ditemukan.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mencari user: $e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addMemberFromResult(Map<String, dynamic> user) {
    final uid = (user['id'] ?? user['uid'] ?? '').toString();
    if (uid.isEmpty) return;

    if (_memberIds.contains(uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member sudah ditambahkan.')),
      );
      return;
    }

    setState(() {
      _memberIds.add(uid);
      _memberProfiles[uid] = {
        'name': (user['name'] ?? '').toString(),
        'email': (user['email'] ?? '').toString(),
        'photoUrl': (user['photoUrl'] ?? '').toString(),
      };
    });
  }

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    final desc = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_memberIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 member lain.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otherMembers = _memberIds.where((id) => id != _myUid).toList();

      await _fs.createGroup(
        name: name,
        description: desc,
        memberIds: otherMembers,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created successfully'),
          backgroundColor: Color(0xFF0A2E5C),
        ),
      );

      navigateReplacementWithFade(context, const GroupsPage());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2E5C),
      appBar: AppBar(
        title: const Text(
          'Create Group',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A2E5C),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Name',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _groupNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter group name',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter group description',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Add Members (by Email)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailSearchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'contoh: teman@gmail.com',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchByEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // chips member terpilih
            if (_memberIds.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _memberIds.map((uid) {
                  final isMe = uid == _myUid;
                  final p = _memberProfiles[uid] ?? {};
                  final name = (p['name'] ?? '').toString();
                  final email = (p['email'] ?? '').toString();

                  return Chip(
                    label: Text(
                      isMe
                          ? 'You'
                          : (name.isNotEmpty
                                ? name
                                : (email.isNotEmpty ? email : uid)),
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: isMe
                        ? null
                        : () {
                            setState(() {
                              _memberIds.remove(uid);
                              _memberProfiles.remove(uid);
                            });
                          },
                    backgroundColor: Colors.white,
                    labelStyle: const TextStyle(
                      color: Color(0xFF0A2E5C),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // hasil pencarian user
            if (_searchResults.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = _searchResults[i];
                    final uid = (u['id'] ?? u['uid'] ?? '').toString();
                    final name = (u['name'] ?? '').toString();
                    final email = (u['email'] ?? '').toString();
                    final photoUrl = (u['photoUrl'] ?? '').toString();

                    final alreadyAdded = _memberIds.contains(uid);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/profile.jpg')
                                  as ImageProvider,
                      ),
                      title: Text(name.isNotEmpty ? name : email),
                      subtitle: Text(email),
                      trailing: alreadyAdded
                          ? const Icon(Icons.check, color: Colors.green)
                          : const Icon(Icons.add, color: Color(0xFF0A2E5C)),
                      onTap: alreadyAdded
                          ? null
                          : () => _addMemberFromResult(u),
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
