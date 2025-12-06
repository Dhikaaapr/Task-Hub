import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/navigation_helper.dart';
import '../pages/dashboard_page.dart';
import '../auth/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// 🔹 Validasi Login Manual
  void _login(BuildContext context) {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email dan password harus diisi!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    navigateReplacementWithFade(context, const DashboardPage());
  }

  /// 🔹 Login Google Dummy → Langsung Masuk Dashboard
  void _loginWithGoogle(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Login Google berhasil"),
        backgroundColor: Colors.green,
      ),
    );

    navigateReplacementWithFade(context, const DashboardPage());
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/logotask.svg', height: 80),
                const SizedBox(height: 20),
                const Text(
                  "Masuk ke akun anda",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2E5C),
                  ),
                ),
                const SizedBox(height: 20),

                /// 🔹 Input Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔹 Input Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔹 Tombol Login
                ElevatedButton(
                  onPressed: () => _login(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2E5C),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Login"),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun? "),
                    InkWell(
                      onTap: () {
                        navigateWithFade(context, const RegisterPage());
                      },
                      child: const Text(
                        "Daftar",
                        style: TextStyle(
                          color: Color(0xFF0A2E5C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Atau Login dengan:",
                  style: TextStyle(fontSize: 14, color: Color(0xFF0A2E5C)),
                ),
                const SizedBox(height: 12),

                /// 🔹 Icon Google Login Dummy
                InkWell(
                  onTap: () => _loginWithGoogle(context),
                  child: SvgPicture.asset('assets/icongoogle.svg', height: 35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
