import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home/home_screen_tab.dart';
import 'network/network_screen.dart';
import 'home_screen.dart'; // Existing — used as Explore tab
import 'compete/compete_screen.dart';
import 'profile/profile_screen.dart'; // Existing

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreenTab(),
    NetworkScreen(),
    HomeScreen(), // Existing opportunities screen → Explore tab
    CompeteScreen(),
    ProfileScreen(),
  ];

  Widget _buildAvatarIcon({required bool isSelected}) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.black : const Color(0xFFBDBDBD),
          width: isSelected ? 2 : 1.5,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 16,
                  color: Color(0xFFBDBDBD),
                ),
              )
            : const Icon(
                Icons.person,
                size: 16,
                color: Color(0xFFBDBDBD),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFF0F0F0),
              width: 1,
            ),
          ),
        ),
        child: SizedBox(
          height: 60,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: const Color(0xFFBDBDBD),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            iconSize: 26,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.work_outline),
                activeIcon: Icon(Icons.work),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.bolt_outlined),
                activeIcon: Icon(Icons.bolt),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildAvatarIcon(isSelected: _currentIndex == 4),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
