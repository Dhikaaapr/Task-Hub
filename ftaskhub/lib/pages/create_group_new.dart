import 'package:flutter/material.dart';
import '../models/task_hub_service.dart';
import '../models/user.dart';
import '../pages/group_detail_page.dart';

class CreateGroupPageNew extends StatefulWidget {
  const CreateGroupPageNew({super.key});

  @override
  State<CreateGroupPageNew> createState() => _CreateGroupPageNewState();
}

class _CreateGroupPageNewState extends State<CreateGroupPageNew> {
  final TaskHubService _taskHubService = TaskHubService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _memberControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final List<String> _selectedMembers = [];
  final List<User> _allUsers = [];
  
  @override
  void initState() {
    super.initState();
    _taskHubService.initialize();
    // Add current user to the list
    final currentUser = _taskHubService.getUserById('current_user_id')!;
    _allUsers.add(currentUser);
    // Add some sample users
    _allUsers.add(User(
      id: 'user1',
      name: 'Andhika',
      email: 'andhika@example.com',
      avatarUrl: 'assets/profile.jpg',
    ));
    _allUsers.add(User(
      id: 'user2',
      name: 'Zaki',
      email: 'zaki@example.com',
      avatarUrl: 'assets/profile.jpg',
    ));
    _allUsers.add(User(
      id: 'user3',
      name: 'Najuan',
      email: 'najuan@example.com',
      avatarUrl: 'assets/profile.jpg',
    ));
    _selectedMembers.add('current_user_id'); // Add current user by default
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    for (final controller in _memberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _createGroup() {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMembers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one other member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final group = _taskHubService.createGroup(
      name: _groupNameController.text.trim(),
      description: _descriptionController.text.trim(),
      creatorId: 'current_user_id',
      memberIds: _selectedMembers.where((id) => id != 'current_user_id').toList(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailPage(
          group: group,
          currentUser: _taskHubService.getUserById('current_user_id')!,
        ),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Group created successfully'),
        backgroundColor: Color(0xFF0A2E5C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableUsers = _allUsers
        .where((user) => !_selectedMembers.contains(user.id))
        .toList();

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
            // Group name
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

            // Description
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

            // Add members section
            const Text(
              'Add Members',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Selected members
            if (_selectedMembers.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  children: _selectedMembers
                      .map((memberId) {
                        final user = _allUsers.firstWhere(
                          (u) => u.id == memberId,
                          orElse: () => User(
                            id: '',
                            name: '',
                            email: '',
                            avatarUrl: '',
                          ),
                        );
                        return Chip(
                          label: Text(
                            user.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 18,
                          ),
                          onDeleted: memberId == 'current_user_id'
                              ? null // Can't remove current user
                              : () {
                                  setState(() {
                                    _selectedMembers.remove(memberId);
                                  });
                                },
                          backgroundColor: Colors.white,
                          labelStyle: const TextStyle(
                            color: Color(0xFF0A2E5C),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      })
                      .toList(),
                ),
              ),

            // Available members dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text(
                    'Select members to add',
                    style: TextStyle(color: Colors.white54),
                  ),
                  value: null,
                  items: availableUsers.map((user) {
                    return DropdownMenuItem(
                      value: user.id,
                      child: Text(
                        user.name,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedMembers.add(value);
                      });
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // Create button
            Center(
              child: ElevatedButton(
                onPressed: _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
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