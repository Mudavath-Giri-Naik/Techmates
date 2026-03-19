import 'package:flutter/material.dart';
import '../screens/profile/profile_screen.dart';
import 'smart_avatar.dart';

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
    this.showLeadingAvatar = true,
  });

  final List<Widget>? actions;
  final ValueChanged<String>? onSearch; // Callback for search query
  final String searchHint;
  final bool showAppBar;
  final bool showLeadingAvatar;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
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

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      appBar: widget.showAppBar
          ? AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 56,
              centerTitle: true,
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 18),
                      onChanged: (value) {
                        if (widget.onSearch != null) {
                          widget.onSearch!(value);
                        }
                      },
                    )
                  : widget.titleWidget ??
                      (widget.title == 'Techmates'
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: colorScheme.onSurface,
                              ),
                            )),
              leadingWidth: (_isSearching || widget.showLeadingAvatar) ? 60 : 0,
              leading: _isSearching
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Center(
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchController.clear();
                              if (widget.onSearch != null) {
                                widget.onSearch!('');
                              }
                            });
                          },
                        ),
                      ),
                    )
                  : (widget.showLeadingAvatar
                      ? Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Center(
                            child: SmartAvatar(
                              size: 40,
                              isEditable: false,
                              onTap: _openProfile,
                            ),
                          ),
                        )
                      : null),
              actions: [
                if (widget.actions != null && !_isSearching) Row(children: widget.actions!),
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
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : null,
      body: SafeArea(child: widget.child),
    );
  }
}
