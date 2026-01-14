import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../admin_navigation.dart';
import '../../main_navigation.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AuthService.getCurrentUserRole(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snap.error}')));
        }

        final role = snap.data ?? '';
        if (role == 'admin') return const AdminNavigation();
        return const MainNavigation();
      },
    );
  }
}
