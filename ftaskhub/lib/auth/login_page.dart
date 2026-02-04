import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../pages/dashboard_page.dart';
import '../auth/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _loading = false;
  bool _isPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _loginEmail() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showError("Email dan password wajib diisi");
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.signInWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        await _firestoreService.upsertMyUserProfile();
        if (!mounted) return;
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
      if (user != null) {
        await _firestoreService.upsertMyUserProfile();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      _showError("Login Google gagal: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Dark Modern Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Deep Slate
                  Color(0xFF1E293B), // Slate
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),

          // 2. Abstract Glowing Orbs (Decorations)
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          // 3. Main Glass Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Enhanced Logo Presentation
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        // Wrap logo in another white circle if it needs contrast
                        child: Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                           ),
                           child: SvgPicture.asset('assets/logotask.svg', height: 60),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Glassmorphism Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                "Welcome Back",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Sign in to continue your journey",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Modern Input Email
                              _buildGlassTextField(
                                controller: emailController,
                                icon: Icons.email_rounded,
                                label: "Email",
                              ),
                              const SizedBox(height: 20),

                              // Modern Input Password
                              _buildGlassTextField(
                                controller: passwordController,
                                icon: Icons.lock_rounded,
                                label: "Password",
                                isPassword: true,
                                isVisible: _isPasswordVisible,
                                onVisibilityChanged: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              
                              const SizedBox(height: 32),

                              // Gradient Login Button
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _loginEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text(
                                          "Login",
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
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Social Login
                    Column(
                      children: [
                        Text(
                          "Or continue with",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: _loginGoogle,
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: SvgPicture.asset('assets/icongoogle.svg', height: 32),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Register Link
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          children: const [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  onPressed: onVisibilityChanged,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
