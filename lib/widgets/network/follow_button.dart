import 'package:flutter/material.dart';
import '../../models/follow_model.dart';
import '../../services/follow_service.dart';

/// A reusable follow button with optimistic UI updates.
///
/// Two variants:
/// - **compact** (default) — smaller, used inside list cards.
/// - **full** — larger, used on the student profile screen.
class FollowButton extends StatefulWidget {
  final String targetUserId;
  final FollowStatus initialStatus;
  final bool compact;
  final ValueChanged<FollowStatus>? onStatusChanged;

  const FollowButton({
    super.key,
    required this.targetUserId,
    required this.initialStatus,
    this.compact = true,
    this.onStatusChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  late FollowStatus _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  @override
  void didUpdateWidget(covariant FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus) {
      _status = widget.initialStatus;
    }
  }

  Future<void> _handleTap() async {
    if (_isLoading || _status == FollowStatus.self) return;

    final previousStatus = _status;

    // Optimistic update
    FollowStatus optimistic;
    switch (_status) {
      case FollowStatus.none:
        optimistic = FollowStatus.pending;
        break;
      case FollowStatus.pending:
      case FollowStatus.following:
        optimistic = FollowStatus.none;
        break;
      case FollowStatus.self:
        return;
    }

    setState(() {
      _status = optimistic;
      _isLoading = true;
    });
    widget.onStatusChanged?.call(optimistic);

    try {
      final result = await FollowService().toggleFollow(
        targetUserId: widget.targetUserId,
        currentStatus: previousStatus,
      );

      if (mounted) {
        setState(() {
          _status = result;
          _isLoading = false;
        });
        widget.onStatusChanged?.call(result);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _status = previousStatus;
          _isLoading = false;
        });
        widget.onStatusChanged?.call(previousStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == FollowStatus.self) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isFilled = _status == FollowStatus.none;
    final label = _status.label;

    final horizontalPad = widget.compact ? 14.0 : 16.0;
    final verticalPad = widget.compact ? 6.0 : 6.0;
    final fontSize = widget.compact ? 12.0 : 13.0;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPad,
          vertical: verticalPad,
        ),
        decoration: BoxDecoration(
          color: isFilled ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFilled
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: fontSize,
                height: fontSize,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: isFilled ? Colors.white : colorScheme.primary,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: isFilled
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
      ),
    );
  }
}
