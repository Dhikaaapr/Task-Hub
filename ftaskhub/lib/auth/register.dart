import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../pages/dashboard_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;

  Future<void> _register() async {
    if (passwordController.text != confirmController.text) {
      _showError("Password tidak sama");
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.registerWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      _showError("Email sudah terdaftar");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2E5C),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SvgPicture.asset('assets/logotask.svg', height: 80),
                const SizedBox(height: 20),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Konfirmasi Password",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text("Daftar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
