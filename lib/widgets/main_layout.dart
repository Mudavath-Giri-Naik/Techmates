import 'package:flutter/material.dart';
import 'smart_avatar.dart';
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
    this.showAppBar = true,
  });

  final List<Widget>? actions;
  final ValueChanged<String>? onSearch; // Callback for search query
  final String searchHint;
  final bool showAppBar;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearching = false;
  late AnimationController _searchAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      floatingActionButton: widget.floatingActionButton,
      appBar: widget.showAppBar ? AppBar(
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
      ) : null,

      drawer: const ProfileDrawer(),
      body: widget.child,
    );
  }
}
