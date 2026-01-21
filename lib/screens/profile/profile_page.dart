import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'my_listings_page.dart';
import '../../models/listing_item.dart';
import '../orders/order_history_page.dart';
import '../orders/seller_orders_page.dart';
import 'edit_profile_page.dart';
import '../warnings/warnings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
      appBar: AppBar(title: const Text('My Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Info Section
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Student',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              ),
            ),
            const SizedBox(height: 30),

            // Menu Section
            _buildMenuTile(
              context,
              icon: Icons.shopping_bag,
              title: 'My Products',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const MyListingsPage(type: ListingType.product),
                ),
              ),
            ),
            _buildMenuTile(
              context,
              icon: Icons.swap_horiz,
              title: 'My Swaps',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const MyListingsPage(type: ListingType.exchange),
                ),
              ),
            ),
            _buildMenuTile(
              context,
              icon: Icons.store,
              title: 'My Business Promotions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const MyListingsPage(type: ListingType.promotion),
                ),
              ),
            ),
            _buildMenuTile(
              context,
              icon: Icons.receipt_long,
              title: 'Order History',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderHistoryPage(),
                ),
              ),
            ),
            _buildMenuTile(
              context,
              icon: Icons.storefront,
              title: 'My Sales',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SellerOrdersPage(),
                ),
              ),
            ),
            _buildMenuTile(
              context,
              icon: Icons.warning,
              title: 'My Warnings',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WarningsPage(),
                ),
              ),
            ),

            const Divider(height: 40),

            _buildMenuTile(
              context,
              icon: Icons.logout,
              title: 'Logout',
              color: Colors.red,
              onTap: () => _logout(context),
            ),
          ],
        ),
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
      leading: Icon(icon, color: color ?? Colors.blue),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
