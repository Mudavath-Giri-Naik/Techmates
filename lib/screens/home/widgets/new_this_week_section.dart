import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/opportunity_model.dart';
import '../../../services/bookmark_service.dart';
import '../home_theme.dart';

/// Section 5 — "New This Week" with fresh counter banner + feed cards.
class NewThisWeekSection extends StatefulWidget {
  final List<Opportunity> items;
  final int newSinceLastVisit;
  final VoidCallback? onViewAll;

  const NewThisWeekSection({
    super.key,
    required this.items,
    this.newSinceLastVisit = 0,
    this.onViewAll,
  });

  @override
  State<NewThisWeekSection> createState() => _NewThisWeekSectionState();
}

class _NewThisWeekSectionState extends State<NewThisWeekSection>
    with TickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late List<AnimationController> _cardCtrls;
  final _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    // 🔥 bounce animation
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Staggered fade-up for feed cards
    _cardCtrls = List.generate(widget.items.length, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    });
    _startStaggered();
  }

  void _startStaggered() async {
    for (int i = 0; i < _cardCtrls.length; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (mounted) _cardCtrls[i].forward();
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    for (final c in _cardCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New This Week',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.onSurface(context),
                ),
              ),
              GestureDetector(
                onTap: widget.onViewAll,
                child: Text(
                  'View all',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HomeTheme.primary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fresh counter banner
          if (widget.newSinceLastVisit > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: HomeTheme.primaryContainer(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _bounceCtrl,
                    builder: (_, __) {
                      final dy = -4.0 * _bounceCtrl.value;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: const Text('🔥', style: TextStyle(fontSize: 18)),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: HomeTheme.onPrimaryContainer(context),
                        ),
                        children: [
                          TextSpan(
                            text: '${widget.newSinceLastVisit}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text: ' new opportunities since your last visit',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Feed cards
          ...List.generate(widget.items.length, (i) {
            return AnimatedBuilder(
              animation: _cardCtrls[i],
              builder: (_, __) {
                final opacity = _cardCtrls[i].value;
                final dy = 16 * (1 - _cardCtrls[i].value);
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildFeedCard(widget.items[i], context),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeedCard(Opportunity op, BuildContext context) {
    final isBookmarked = _bookmarkService.isBookmarked(op.id);
    final deadlineText = DateFormat('MMM d').format(op.deadline);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: navigate to opportunity detail
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : HomeTheme.surfaceContainerLow(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HomeTheme.outlineVariant(context), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: HomeTheme.typeChipBg(context, op.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      op.type.toUpperCase(),
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: HomeTheme.typeChipText(context, op.type),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    op.title,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HomeTheme.onSurface(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Meta row
                  Text(
                    '${op.organization} · ${op.location} · $deadlineText',
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      color: HomeTheme.onSurfaceVariant(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bookmark
            GestureDetector(
              onTap: () {
                _bookmarkService.toggleBookmark(op);
                setState(() {});
              },
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                size: 22,
                color: isBookmarked
                    ? HomeTheme.primary(context)
                    : HomeTheme.onSurfaceVariant(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
