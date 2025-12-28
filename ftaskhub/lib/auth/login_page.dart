import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../pages/dashboard_page.dart';
import '../auth/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;

  Future<void> _loginEmail() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _showError("Email dan password wajib diisi");
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.signInWithEmail(
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
      _showError("Email atau password salah");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      _showError("Login Google gagal");
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

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : _loginEmail,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),

                const SizedBox(height: 20),
                const Text("Atau login dengan"),

                const SizedBox(height: 12),

                InkWell(
                  onTap: _loading ? null : _loginGoogle,
                  child: SvgPicture.asset(
                    'assets/icongoogle.svg',
                    height: 40,
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text("Belum punya akun? Daftar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
