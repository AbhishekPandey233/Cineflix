import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'signup_screen.dart';
import '../../../dashboard/presentation/pages/home_screen.dart';
import '../view_model/auth_view_model.dart';
import '../state/auth_state.dart';
import 'package:ceniflix/features/sensor/presentation/view_model/biometric_view_model.dart';
import 'package:ceniflix/features/sensor/presentation/state/biometric_state.dart';
import 'package:ceniflix/core/services/storage/user_session_service.dart';
import 'package:ceniflix/features/auth/domain/entities/auth_entity.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // ✅ Listener added once (safe)
    ref.listenManual<AuthState>(authViewModelProvider, (prev, next) {
      if (!mounted) return;

      if (next.status == AuthStatus.error && next.errorMessage != null) {
        _showSnack(next.errorMessage!);
      }

      if (next.status == AuthStatus.authenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });

    ref.listenManual<BiometricState>(biometricViewModelProvider, (prev, next) {
      if (!mounted) return;
      if (next.status == BiometricStatus.error && next.errorMessage != null) {
        _showSnack(next.errorMessage!);
      }
    });

  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

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
                    child: const Icon(Icons.lock_outline,
                        size: 60, color: Color(0xFFEF233C)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Login to continue your journey",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                  const SizedBox(height: 40),

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
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration(
                              "Email Address", Icons.email_outlined),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration(
                              "Password", Icons.lock_open_rounded),
                        ),
                        const SizedBox(height: 30),

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
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final email = _emailCtrl.text.trim();
                                    final password = _passCtrl.text;
                                    if (email.isEmpty || password.isEmpty) {
                                      _showSnack("Please enter credentials");
                                      return;
                                    }
                                    await ref
                                        .read(authViewModelProvider.notifier)
                                        .login(email: email, password: password);
                                  },
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
                                    "LOGIN",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                        final accountId =
                                          _emailCtrl.text.trim().toLowerCase();
                                      if (accountId.isEmpty) {
                                        _showSnack(
                                            "Enter your email to use biometrics");
                                        return;
                                      }

                                      final success = await ref
                                          .read(biometricViewModelProvider
                                              .notifier)
                                          .loginWithBiometrics(accountId);
                                      if (!success || !mounted) return;

                                        final binding = await ref
                                          .read(biometricViewModelProvider
                                            .notifier)
                                          .getBinding();

                                        final session =
                                          ref.read(userSessionServiceProvider);
                                        if (binding != null) {
                                        await session.saveUserSession(
                                          userId: binding.userId ?? accountId,
                                          email: binding.email ?? accountId,
                                          fullName:
                                            binding.fullName ?? accountId,
                                        );
                                          if (binding.token != null &&
                                              binding.token!.isNotEmpty) {
                                            await session.saveToken(binding.token!);
                                          }
                                          ref
                                              .read(authViewModelProvider.notifier)
                                              .authenticateFromBinding(
                                                AuthEntity(
                                                  authId:
                                                      binding.userId ?? accountId,
                                                  fullName:
                                                      binding.fullName ?? accountId,
                                                  username:
                                                      binding.fullName ?? accountId,
                                                  email: binding.email ?? accountId,
                                                ),
                                              );
                                          if (!mounted) return;
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const HomeScreen(),
                                            ),
                                          );
                                          return;
                                        }
                                        _showSnack(
                                            "No biometric binding found for this account");
                                    },
                              icon: const Icon(Icons.fingerprint),
                              label: const Text(
                                "SIGN IN WITH FINGERPRINT",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            );
                          },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: const TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  Colors.white.withOpacity(0.5),
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
      ),
    );
  }
}
