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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final stats =
              snapshot.data ??
              const {
                'products': 0,
                'exchanges': 0,
                'promotions': 0,
                'users': 0,
              };

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  title: 'Total Students',
                  value: (stats['users'] ?? 0).toString(),
                  color: Colors.blue,
                ),
                _buildStatCard(
                  title: 'Products',
                  value: (stats['products'] ?? 0).toString(),
                  color: Colors.green,
                ),
                _buildStatCard(
                  title: 'Exchanges',
                  value: (stats['exchanges'] ?? 0).toString(),
                  color: Colors.orange,
                ),
                _buildStatCard(
                  title: 'Promotions',
                  value: (stats['promotions'] ?? 0).toString(),
                  color: Colors.purple,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              title,
              style: TextStyle(fontSize: 16, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
