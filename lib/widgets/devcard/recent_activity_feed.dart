import 'package:flutter/material.dart';

import '../../models/devcard/devcard_model.dart';

class RecentActivityFeed extends StatelessWidget {
  final List<CommitActivity> commits;

  const RecentActivityFeed({super.key, required this.commits});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT ACTIVITY',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          if (commits.isEmpty)
            const Text(
              'No recent commits found',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
            )
          else
            ...commits.map((c) => _commitRow(c)),
        ],
      ),
    );
  }

  Widget _commitRow(CommitActivity c) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF238636),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.message,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.repoName,
                          style: const TextStyle(
                              color: Color(0xFF58A6FF), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('  ·  ${_timeAgo(c.committedDate)}',
                          style: const TextStyle(
                              color: Color(0xFF8B949E), fontSize: 11)),
                      if (c.additions > 0 || c.deletions > 0) ...[
                        Text('  +${c.additions}',
                            style: const TextStyle(
                                color: Color(0xFF3FB950), fontSize: 11)),
                        Text(' -${c.deletions}',
                            style: const TextStyle(
                                color: Color(0xFFF85149), fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xFF21262D), height: 16),
      ],
    );
  }
}
