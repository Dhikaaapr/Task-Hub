import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/navigation_helper.dart';
import 'create_group_page.dart';
import 'taskmanage.dart';
import 'schedule_page.dart';
import '../auth/login_page.dart';
import 'chat_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Color primaryBlue = const Color(0xFF0A2E5C);
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        navigateWithFade(context, const MustToDoPage());
        break;
      case 1:
        navigateWithFade(context, const SchedulePage());
        break;
      case 2:
        navigateWithFade(context, const CreateGroupPage());
        break;
      case 3:
        navigateWithFade(
          context,
          ChatPage(
            groupTitle: "Kelompok 2",
            members: const ["Andhika", "zaki", "Najuan"],
          ),
        );

        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header profile
            ListTile(
              leading: GestureDetector(
                onTap: () => _showProfileOptions(context),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
              ),
              title: const Text(
                "Andhika Presha Saputra",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                "Paramadina University",
                style: TextStyle(color: Colors.white70),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    // Must To Do baru (sesuai desain)
                    _buildMustToDoSection(context),

                    // Schedule
                    _buildCard(
                      title: "Schedule",
                      child: GestureDetector(
                        onTap: () =>
                            navigateWithFade(context, const SchedulePage()),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: 28,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Menu bawah (Chat / Video / ChatBot / Calendar)
                    Container(
                      color: primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMenu(
                            Icons.chat,
                            "Chat Group",
                            context,
                            onTap: () {
                              navigateWithFade(
                                context,
                                ChatPage(
                                  groupTitle: "Kelompok Dummy",
                                  members: const ["Andhika", "Budi", "Siti"],
                                ),
                              );
                            },
                          ),

                          _buildMenu(
                            Icons.video_call,
                            "Conference",
                            context,
                            onTap: () async {
                              final Uri url = Uri.parse(
                                "http://meet.google.com/nzo-xscv-fej",
                              );
                              if (!await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              )) {
                                throw Exception('Could not launch $url');
                              }
                            },
                          ),
                          _buildMenu(Icons.smart_toy, "ChatBot", context),
                          _buildMenu(Icons.calendar_month, "Calendar", context),
                        ],
                      ),
                    ),

                    // Berita
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      height: 100,
                      child: const Center(
                        child: Text(
                          "Berita terkini akan muncul di sini",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
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
              icon: Icon(Icons.task_alt_outlined),
              label: 'TASK Manage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.add, color: Color(0xFF0A2E5C)),
              ),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }

  // ==== WIDGET KHUSUS MUST TO DO DI DASHBOARD ====

  Widget _buildMustToDoSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + See All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Task Manage",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () =>
                    navigateWithFade(context, const MustToDoPage()),
                child: const Text("See All", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // hanya 3 task teratas sebagai preview
          ...dummyTasks.take(3).map((task) => TaskCard(task: task)),

          const SizedBox(height: 16),
          const Text(
            'Progress Accumulative',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('60%', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildCard({required Widget child, String? title}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildMenu(
    IconData icon,
    String title,
    BuildContext context, {
    Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => navigateWithFade,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black87, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
