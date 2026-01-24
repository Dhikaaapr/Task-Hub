import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/login_page.dart';
import '../utils/navigation_helper.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName {
    final name = _user?.displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    final email = _user?.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  Future<void> _logout(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    navigateReplacementWithFade(context, const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A2E5C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: _user?.photoURL != null
                      ? DecorationImage(
                          image: NetworkImage(_user!.photoURL!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _user?.photoURL == null
                    ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2E5C),
              ),
            ),
            Text(
              _user?.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _buildProfileItem(
              icon: Icons.person_outline,
              text: 'Edit Profile',
              onTap: () {},
            ),
            _buildProfileItem(
              icon: Icons.lock_outline,
              text: 'Change Password',
              onTap: () {},
            ),
            _buildProfileItem(
              icon: Icons.notifications_none,
              text: 'Notifications',
              onTap: () {},
            ),
            const Divider(height: 32),
            _buildProfileItem(
              icon: Icons.logout,
              text: 'Logout',
              isDestructive: true,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : const Color(0xFF0A2E5C);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
