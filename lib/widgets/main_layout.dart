import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import 'smart_avatar.dart';
import '../screens/edit_profile_screen.dart';
import '../services/profile_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_drawer.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String title; // Optional override
  final Widget? floatingActionButton;
  final Widget? titleWidget; // Optional custom title widget

  const MainLayout({
    super.key,
    required this.child,
    this.title = "Techmates",
    this.titleWidget,
    this.floatingActionButton,
    this.actions,
    this.onSearch,
    this.searchHint = 'Search...',
  });

  final List<Widget>? actions;
  final ValueChanged<String>? onSearch; // Callback for search query
  final String searchHint;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _auth = AuthService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();
  
  String? _userName;
  bool _isSearching = false;
  late AnimationController _searchAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fetchProfileName();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileName() async {
    final user = _auth.user;
    if (user != null) {
      final profile = await _profileService.fetchProfile(user.id);
      if (mounted) {
        setState(() {
          _userName = profile?.name;
        });
      }
    }
  }

  /* Feedback and logout moved to ProfileDrawer */


  @override
  Widget build(BuildContext context) {
    // Check if user is logged in to show correct avatar/name
    final userEmail = _auth.user?.email ?? "User";
    final displayName = _userName ?? "User";


    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white, // Global White Background
      floatingActionButton: widget.floatingActionButton,
      appBar: AppBar(
        backgroundColor: Colors.white, // Flat White AppBar
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56, // Reduced from 70
        centerTitle: true, // Keep title in middle
        // titleSpacing: 12, // Default spacing works for centered title
        
        // Dynamic Title Logic
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.black, fontSize: 18),
              onChanged: (value) {
                if (widget.onSearch != null) {
                  widget.onSearch!(value);
                }
              },
            )
          : widget.titleWidget ?? (widget.title == 'Techmates' 
              ? RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), 
                    children: [
                      TextSpan(text: 'Tech', style: TextStyle(color: Colors.red)),
                      TextSpan(text: 'mates', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                )
              : Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                )),
        
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    if (widget.onSearch != null) {
                      widget.onSearch!(''); // Clear search
                    }
                  });
                },
              )
            : SmartAvatar(
                size: 40,
                isEditable: false,
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
          ),
        ),
        actions: [
          if (widget.actions != null && !_isSearching) 
            Row(children: widget.actions!),
          
          if (widget.onSearch != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTapDown: (_) => _searchAnimationController.forward(),
              onTapUp: (_) {
                _searchAnimationController.reverse();
                if (_isSearching) {
                   setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      if (widget.onSearch != null) {
                        widget.onSearch!('');
                      }
                   });
                } else {
                   setState(() {
                     _isSearching = true;
                   });
                }
              },
              onTapCancel: () => _searchAnimationController.reverse(),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.transparent, 
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: child.key == const ValueKey('close') 
                          ? Tween<double>(begin: 0.75, end: 1.0).animate(anim) 
                          : Tween<double>(begin: 0.75, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      _isSearching ? Icons.close : Icons.search,
                      key: ValueKey(_isSearching ? 'close' : 'search'),
                      size: 32,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      drawer: ProfileDrawer(
         displayName: displayName,
         email: userEmail,
      ),
      body: widget.child,
    );
  }
}
