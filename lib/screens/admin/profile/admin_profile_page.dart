import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../auth/login_page.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Admin Badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade700, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 50,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Administrator',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Admin Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(Icons.people, 'Total Users', '---'),
                    const Divider(),
                    _buildStatRow(Icons.shopping_bag, 'Total Products', '---'),
                    const Divider(),
                    _buildStatRow(Icons.report, 'Pending Reports', '---'),
                    const Divider(),
                    _buildStatRow(Icons.store, 'Pending Approvals', '---'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Admin Actions
            Card(
              child: Column(
                children: [
                  _buildMenuTile(
                    context,
                    icon: Icons.settings,
                    title: 'Admin Settings',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Admin settings coming soon'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    context,
                    icon: Icons.analytics,
                    title: 'View Analytics',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Analytics coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    context,
                    icon: Icons.backup,
                    title: 'Backup Data',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup feature coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout
            Card(
              child: _buildMenuTile(
                context,
                icon: Icons.logout,
                title: 'Logout',
                color: Colors.red,
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.purple),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
