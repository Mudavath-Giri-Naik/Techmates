import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/proxy_url.dart';

import 'home/home_screen_tab.dart';
import 'network/network_screen.dart';
import 'home_screen.dart'; // Existing — used as Explore tab
import 'compete/compete_screen.dart';
import 'profile/profile_screen.dart'; // Existing
import '../widgets/offline_banner.dart';

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
    final avatarUrl = proxyUrl(user?.userMetadata?['avatar_url'] as String?);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).colorScheme.onSurface 
              : Theme.of(context).colorScheme.outline,
          width: isSelected ? 2 : 1.5,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
      ),
    );
  }

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A2533)
                : const Color(0xFFD1E7FE),
            height: 72,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group_rounded),
              label: 'Network',
            ),
            NavigationDestination(
              icon: Badge(
                smallSize: 8,
                backgroundColor: Theme.of(context).colorScheme.error,
                child: const Icon(Icons.work_outline_rounded),
              ),
              selectedIcon: Badge(
                smallSize: 8,
                backgroundColor: Theme.of(context).colorScheme.error,
                child: const Icon(Icons.work_rounded),
              ),
              label: 'Explore',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bolt_outlined),
              selectedIcon: Icon(Icons.bolt_rounded),
              label: 'Compete',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
    );
  }
}
