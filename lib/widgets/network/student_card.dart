import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/student_network_model.dart';
import '../../models/follow_model.dart';
import 'follow_button.dart';

/// A card that displays a student's info inside the college dashboard list.
class StudentCard extends StatefulWidget {
  final StudentNetworkModel student;
  final VoidCallback? onTap;
  final ValueChanged<FollowStatus>? onFollowChanged;
  final int? rank; // null = no rank badge

  const StudentCard({
    super.key,
    required this.student,
    this.onTap,
    this.onFollowChanged,
    this.rank,
  });

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  late StudentNetworkModel _student;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
  }

  @override
  void didUpdateWidget(covariant StudentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.student.id != oldWidget.student.id ||
        widget.student.followStatus != oldWidget.student.followStatus) {
      _student = widget.student;
    }
  }

  void _onFollowStatusChanged(FollowStatus newStatus) {
    final previousStatus = _student.followStatus;
    int delta = 0;
    if (previousStatus == FollowStatus.none && newStatus != FollowStatus.none) {
      // We just followed/requested — some RPCs auto-accept
      if (newStatus == FollowStatus.following) delta = 1;
    } else if (previousStatus == FollowStatus.following &&
        newStatus == FollowStatus.none) {
      delta = -1;
    }

    setState(() {
      _student = _student.copyWith(
        followStatus: newStatus,
        followerCount:
            (_student.followerCount + delta).clamp(0, 999999999),
      );
    });
    widget.onFollowChanged?.call(newStatus);
  }

  Widget _buildAvatar() {
    final url = _student.avatarUrl;
    final initial =
        _student.displayName.isNotEmpty ? _student.displayName[0].toUpperCase() : '?';

    Widget fallback = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => fallback,
          placeholder: (_, _) => fallback,
        ),
      );
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // Rank badge (if provided)
            if (widget.rank != null) ...[
              _buildRankBadge(widget.rank!),
              const SizedBox(width: 8),
            ],

            // Avatar
            _buildAvatar(),
            const SizedBox(width: 12),

            // Name, branch, stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _student.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_student.isPrivate) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Branch
                  if (_student.branch != null && _student.branch!.isNotEmpty)
                    Text(
                      _student.branch!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  // Score + follower count
                  Row(
                    children: [
                      if (_student.githubScore > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                '${_student.githubScore}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatCount(_student.followerCount),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Follow button
            FollowButton(
              targetUserId: _student.id,
              initialStatus: _student.followStatus,
              compact: true,
              onStatusChanged: _onFollowStatusChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    switch (rank) {
      case 1:
        badgeColor = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}
