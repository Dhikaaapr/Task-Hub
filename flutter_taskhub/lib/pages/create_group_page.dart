import 'package:flutter/material.dart';
import '../pages/taskmanage.dart';
import 'create_chat_group_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController groupNameController = TextEditingController();
  final List<TextEditingController> memberControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  void _goToNextPage() {
    final groupName = groupNameController.text.trim();
    final members = memberControllers
        .where((controller) => controller.text.isNotEmpty)
        .map((e) => e.text)
        .toList();

    if (groupName.isNotEmpty && members.isNotEmpty) {
      // 🔥 Simpan group ke TaskManage
      addGroupToTasks(groupName, members);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CreateChatGroupPage(groupName: groupName, members: members),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi nama kelompok & minimal 1 anggota")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2E5C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                title: Text(
                  "Mamat Sudrajad",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Paramadina University",
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Buat Kelompok",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildTextField("Nama Kelompok", groupNameController),
              const SizedBox(height: 16),

              for (int i = 0; i < memberControllers.length; i++) ...[
                _buildTextField("Nama Anggota ${i + 1}", memberControllers[i]),
                const SizedBox(height: 16),
              ],

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      memberControllers.add(TextEditingController());
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0A2E5C),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add),
                ),
              ),

              const Spacer(),
              ElevatedButton(
                onPressed: _goToNextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0A2E5C),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Selanjutnya",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
