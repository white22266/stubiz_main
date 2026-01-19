import 'package:flutter/material.dart';
import 'screens/marketplace/marketplace_home.dart';
import 'screens/exchange/exchange_home.dart';
import 'screens/promotion/promotion_home.dart';
import 'screens/chat/chat_list.dart';
import 'screens/profile/profile_page.dart';

class StudentNavigation extends StatefulWidget {
  const StudentNavigation({super.key});

  @override
  State<StudentNavigation> createState() => _StudentNavigationState();
}

class _StudentNavigationState extends State<StudentNavigation> {
  int _index = 0;

  final List<Widget> screens = const [
    MarketplaceHome(),
    ExchangeHome(),
    PromotionHome(),
    ChatListScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Market'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Exchange',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Promote'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
