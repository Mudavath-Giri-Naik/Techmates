import 'package:flutter/material.dart';

import 'home/home_screen_tab.dart';
import 'home_screen.dart'; // Existing — used as Explore tab
import 'compete/compete_screen.dart';
import 'profile/profile_screen.dart'; // Existing
import '../widgets/offline_banner.dart';
import '../widgets/smart_avatar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  /// Switch to a specific tab by index.
  void switchTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  /// Switch to Explore tab and navigate to a specific opportunity.
  void navigateToOpportunity(String opportunityId, String type) {
    setState(() => _currentIndex = 2); // Explore tab is now index 2
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeScreen.exploreKey.currentState?.navigateToItem(opportunityId, type);
    });
  }

  final List<Widget> _screens = [
    const HomeScreenTab(),
    const CompeteScreen(),
    HomeScreen(key: HomeScreen.exploreKey),
    const ProfileScreen(),
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: OfflineBanner(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        elevation: 8,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          // 1. Home
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined, size: 26),
            activeIcon: const Icon(Icons.home, size: 26),
            label: 'Home',
          ),
          // 2. Compete
          BottomNavigationBarItem(
            icon: const Icon(Icons.bolt_outlined, size: 26),
            activeIcon: const Icon(Icons.bolt, size: 26),
            label: 'Compete',
          ),
          // 3. Search
          const BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 26),
            activeIcon: Icon(Icons.search, size: 26),
            label: 'Search',
          ),
          // 4. Profile (SmartAvatar)
          const BottomNavigationBarItem(
            icon: SmartAvatar(size: 26),
            activeIcon: SmartAvatar(size: 28), // slightly larger when active
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
