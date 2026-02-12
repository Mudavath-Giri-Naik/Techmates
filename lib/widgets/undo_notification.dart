import 'package:flutter/material.dart';

class UndoNotification {
  static OverlayEntry? _currentOverlay;
  
  static void show({
    required BuildContext context,
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 3),
    bool showUndo = true,
  }) {
    // Remove any existing notification
    _currentOverlay?.remove();
    _currentOverlay = null;
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => _UndoNotificationWidget(
        message: message,
        onUndo: () {
          overlayEntry.remove();
          _currentOverlay = null;
          onUndo();
        },
        onDismiss: () {
          overlayEntry.remove();
          _currentOverlay = null;
        },
        duration: duration,
        showUndo: showUndo,
      ),
    );
    
    overlay.insert(overlayEntry);
    _currentOverlay = overlayEntry;
  }
}

class _UndoNotificationWidget extends StatefulWidget {
  final String message;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;
  final Duration duration;
  final bool showUndo;
  
  const _UndoNotificationWidget({
    required this.message,
    required this.onUndo,
    required this.onDismiss,
    required this.duration,
    required this.showUndo,
  });
  
  @override
  State<_UndoNotificationWidget> createState() => _UndoNotificationWidgetState();
}

class _UndoNotificationWidgetState extends State<_UndoNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
    
    _controller.forward();
    
    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }
  
  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[900],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (widget.showUndo) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onUndo,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[300],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'UNDO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
