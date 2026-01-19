import 'package:flutter/material.dart';
import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/admin_users_page.dart';
import 'screens/admin/admin_listings_page.dart';
import 'screens/admin/admin_reports_page.dart'; // New reports page
import 'screens/profile/profile_page.dart'; // Reuse profile for logout

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardPage(),
    const AdminUsersPage(),
    const AdminListingsPage(),
    const AdminReportsPage(),
    const ProfilePage(), // Uses generic profile for Logout
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.redAccent, // Distinct color for Admin
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Content'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
