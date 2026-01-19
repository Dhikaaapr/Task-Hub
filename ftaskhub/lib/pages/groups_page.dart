import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/navigation_helper.dart';
import 'create_group_page.dart';
import 'group_detail_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2E5C),
      appBar: AppBar(
        title: const Text(
          'Groups',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A2E5C),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fs.streamMyGroups(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildError('${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return _buildEmptyGroups();
          }

          return _buildGroupsList(groups);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => navigateWithFade(context, const CreateGroupPage()),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Gagal memuat groups:\n$msg',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildEmptyGroups() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 80, color: Colors.white30),
          SizedBox(height: 16),
          Text(
            'No groups yet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first group to start collaborating',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(List<Map<String, dynamic>> groups) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];

          final groupId = (group['id'] ?? '').toString();
          final name = (group['name'] ?? 'Unnamed').toString();
          final desc = (group['description'] ?? '').toString();

          final members = (group['memberIds'] is List)
              ? (group['memberIds'] as List)
              : <dynamic>[];
          final memberCount = members.length;

          if (groupId.isEmpty) {
            return _buildBrokenCard(name, desc);
          }

          // ✅ Progress dihitung dari tasks group ini (done / total)
          return StreamBuilder<List<Map<String, dynamic>>>(
            // ordered:false supaya aman dari index orderBy
            stream: _fs.streamTasksByGroup(groupId, ordered: false),
            builder: (context, taskSnap) {
              final tasks = taskSnap.data ?? [];
              final total = tasks.length;
              final done = tasks.where((t) => (t['status'] == 'done')).length;

              final groupProgress = total == 0 ? 0.0 : (done / total) * 100.0;

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    navigateWithFade(
                      context,
                      GroupDetailPage(groupId: groupId),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A2E5C),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.group,
                                color: Colors.white,
                                size: 24,
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0A2E5C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$memberCount members • $done/$total done',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: groupProgress.round() == 100
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${groupProgress.round()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: groupProgress.round() == 100
                                      ? Colors.green[800]
                                      : Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          desc.isEmpty ? 'No description' : desc,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : (done / total),
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              groupProgress.round() == 100
                                  ? Colors.green
                                  : const Color(0xFF0A2E5C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBrokenCard(String name, String desc) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(name),
        subtitle: Text(desc.isEmpty ? 'No description' : desc),
        trailing: const Icon(Icons.warning, color: Colors.red),
      ),
    );
  }
}
