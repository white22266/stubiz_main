import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../student_navigation.dart'; // Student Nav
import '../../admin_navigation.dart'; // Admin Nav
import '../auth/login_page.dart';

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
    // Simulate splash delay (aesthetic choice, e.g., 2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = AuthService.currentUser;

    if (user != null) {
      // User is logged in, check role
      try {
        final role = await AuthService.getCurrentRole();
        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminNavigation()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentNavigation()),
          );
        }
      } catch (e) {
        // Fallback to login if error
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      // Not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent, // Change to your brand color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your Logo Asset if you have one
            const Icon(Icons.school, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'StuBiz',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'UTHM Student Marketplace',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
