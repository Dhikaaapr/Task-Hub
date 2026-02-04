import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../pages/dashboard_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

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
      _showError("Email sudah terdaftar atau terjadi kesalahan");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
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
            top: -50,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF10B981,
                  ).withValues(alpha: 0.3), // Emerald
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3), // Sky
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
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SvgPicture.asset(
                            'assets/logotask.svg',
                            height: 50,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

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
                                "Create Account",
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
                                "Join the future of task management",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 32),

                              _buildGlassTextField(
                                controller: emailController,
                                icon: Icons.email_rounded,
                                label: "Email",
                              ),
                              const SizedBox(height: 20),

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

                              const SizedBox(height: 20),

                              _buildGlassTextField(
                                controller: confirmController,
                                icon: Icons.lock_outline_rounded,
                                label: "Confirm Password",
                                isPassword: true,
                                isVisible: _isConfirmPasswordVisible,
                                onVisibilityChanged: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                              ),

                              const SizedBox(height: 32),

                              // Gradient Register Button
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          "Sign Up",
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

                    TextButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          children: const [
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
