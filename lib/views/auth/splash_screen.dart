import 'login_screen.dart';
import '../../utils/constants.dart';
import '../member/home_screen.dart';
import '../admin/members_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../visitor/catalogue_screen.dart';
import '../../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthController>();
    await auth.loadCurrentUser();

    if (!mounted) return;

    // Debug — chouf fel terminal
    print('✅ User: ${auth.currentUser?.nom}');
    print('✅ Role: ${auth.userRole}');
    print('✅ Status: ${auth.currentUser?.status}');

    if (auth.isLoggedIn) {
      _redirectByRole(auth.userRole, auth.currentUser?.status ?? '');
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _redirectByRole(String role, String status) {
    print('🔀 Redirecting → role: $role | status: $status');

    Widget screen;

    switch (role) {
      case 'admin':
        screen = const MembersScreen();
        break;
      case 'member':
        if (status == 'pending') {
          context.read<AuthController>().logout();
          screen = const LoginScreen();
        } else {
          screen = const HomeScreen();
        }
        break;
      default:
        screen = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo ────────────────────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Titre ────────────────────────────────────
            const Text(
              'BookShare',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bibliothèque de quartier',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),

            // ── Loading ──────────────────────────────────
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}