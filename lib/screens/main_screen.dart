import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'compete/compete_screen.dart';
import 'search_screen.dart';
import 'profile/profile_screen.dart'; // Existing
import '../widgets/offline_banner.dart';
import '../widgets/smart_avatar.dart';
import '../services/user_role_service.dart';
import 'admin/create_opportunity_screen.dart';

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
    // If notification navigation was to the old Explore tab, it might not work here anymore.
    // Kept as-is to avoid breaking signatures. (If needed, redirect to Home).
    setState(() => _currentIndex = 0); 
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const CompeteScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];



  @override
  Widget build(BuildContext context) {
    final roleService = UserRoleService();

    return Scaffold(
      extendBody: true,
      floatingActionButton: _currentIndex == 0 && roleService.canEdit
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateOpportunityScreen()),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              elevation: 8,
              highlightElevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Icon(Icons.add_rounded, size: 30, color: Theme.of(context).colorScheme.primary),
            )
          : null,
      body: OfflineBanner(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
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
            icon: const Icon(Icons.local_fire_department_outlined, size: 26),
            activeIcon: const Icon(Icons.local_fire_department, size: 26),
            label: 'Compete',
          ),
          // 4. Search
          const BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 26),
            activeIcon: Icon(Icons.search, size: 26),
            label: 'Search',
          ),
          // 5. Profile (SmartAvatar)
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
