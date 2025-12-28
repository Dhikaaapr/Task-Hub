import 'package:flutter/material.dart';
import 'chat_page.dart';

class CreateChatGroupPage extends StatefulWidget {
  final String groupName;
  final List<String> members;

  const CreateChatGroupPage({
    super.key,
    required this.groupName,
    required this.members,
  });

  @override
  State<CreateChatGroupPage> createState() => _CreateChatGroupPageState();
}

class _CreateChatGroupPageState extends State<CreateChatGroupPage> {
  final TextEditingController chatGroupNameController = TextEditingController();
  final TextEditingController rulesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 46, 92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/profile.jpg'),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mamat Sudrajad',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Paramadina University',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'Buat Percakapan Grup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: chatGroupNameController,
                decoration: InputDecoration(
                  hintText: "Masukkan nama Percakapan Grup",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.camera_alt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Peraturan Grup:",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rulesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Masukkan peraturan grup...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Nama Anggota grup:",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: widget.members
                    .map(
                      (m) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            m,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          groupTitle: chatGroupNameController.text.isEmpty
                              ? widget.groupName
                              : chatGroupNameController.text,
                          members: widget.members,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0A2E5C),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Selesai",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
