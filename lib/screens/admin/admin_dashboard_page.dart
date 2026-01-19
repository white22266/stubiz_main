import 'package:flutter/material.dart';
import '../../services/marketplace_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: FutureBuilder<Map<String, int>>(
        future: MarketplaceService.getAdminStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stats =
              snapshot.data ??
              {'products': 0, 'exchanges': 0, 'promotions': 0, 'users': 0};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Users',
                  stats['users'].toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  'Products',
                  stats['products'].toString(),
                  Colors.green,
                ),
                _buildStatCard(
                  'Exchanges',
                  stats['exchanges'].toString(),
                  Colors.orange,
                ),
                _buildStatCard(
                  'Promotions',
                  stats['promotions'].toString(),
                  Colors.purple,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}
