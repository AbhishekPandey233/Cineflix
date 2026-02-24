import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login_screen.dart';
import '../view_model/auth_view_model.dart';
import '../state/auth_state.dart';
import 'package:ceniflix/features/sensor/presentation/view_model/biometric_view_model.dart';
import 'package:ceniflix/features/sensor/presentation/state/biometric_state.dart';
import 'package:ceniflix/core/services/storage/user_session_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _enableBiometrics = false;

  @override
  void initState() {
    super.initState();

    // ✅ Side-effects registered once
    ref.listenManual<AuthState>(
      authViewModelProvider,
      (prev, next) {
        if (!mounted) return;

        if (next.status == AuthStatus.error && next.errorMessage != null) {
          _showSnack(next.errorMessage!);
        }

        if (next.status == AuthStatus.registered) {
          _handlePostRegister();
        }
      },
    );

    ref.listenManual<BiometricState>(biometricViewModelProvider, (prev, next) {
      if (!mounted) return;
      if (next.status == BiometricStatus.error && next.errorMessage != null) {
        _showSnack(next.errorMessage!);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ✅ Same style as your NEW login page
  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFFEF233C), size: 20),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFEF233C), width: 2),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Container(
        width: double.infinity,
        color: const Color(0xFF0D0D0D),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEF233C), width: 2),
                    ),
                    child: const Icon(Icons.person_add_alt_1,
                        size: 60, color: Color(0xFFEF233C)),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Sign up to Book movies!!",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 35),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration("Full Name", Icons.person_outline),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration("Email Address", Icons.email_outlined),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration("Password", Icons.lock_outline),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration("Confirm Password", Icons.lock_open_rounded),
                        ),
                        const SizedBox(height: 26),
                        SwitchListTile.adaptive(
                          value: _enableBiometrics,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() => _enableBiometrics = value);
                                },
                          activeColor: const Color(0xFFEF233C),
                          title: const Text(
                            "Enable fingerprint on this device",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: const Text(
                            "Only this account can use biometrics on this phone",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF233C),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: isLoading ? null : _onSignupPressed,
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "SIGN UP",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ✅ bottom link like login
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: const TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "Log In",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSignupPressed() async {
    FocusScope.of(context).unfocus();

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showSnack("Please fill all fields");
      return;
    }

    if (!email.toLowerCase().endsWith('@gmail.com')) {
      _showSnack("Only Gmail addresses are allowed");
      return;
    }

    if (pass.length < 7) {
      _showSnack("Password must be at least 7 characters");
      return;
    }

    if (pass != confirm) {
      _showSnack("Passwords do not match");
      return;
    }

    await ref.read(authViewModelProvider.notifier).register(
          username: name,
          email: email,
          password: pass,
        );
  }

  Future<void> _handlePostRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final session = ref.read(userSessionServiceProvider);
    final token = await session.getToken();

    if (_enableBiometrics && email.isNotEmpty) {
      final enrolled = await ref
          .read(biometricViewModelProvider.notifier)
          .enrollBiometrics(
            accountId: email,
            userId: session.getCurrentUserId(),
            email: email,
            fullName: name.isEmpty ? null : name,
            token: token,
          );

      if (enrolled) {
        _showSnack("Biometrics enabled for this account");
      }
    }

    if (!mounted) return;
    _showSnack("Registration successful. Please login.");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
