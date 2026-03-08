import 'package:flutter/material.dart';
import '../models/internship_post.dart';
import '../core/theme/internship_carousel_colors.dart';
import 'internship_carousel/slide_hook.dart';
import 'internship_carousel/slide_details.dart';
import 'internship_carousel/slide_about.dart';
import 'internship_carousel/slide_skills.dart';
import 'internship_carousel/slide_cta.dart';

/// A 5-slide horizontally swipeable carousel card for internship opportunities.
///
/// Fixed 4:5 aspect ratio (390 × 487 logical px). Each slide is a self-contained
/// panel communicating one chunk of information. Rendered using [PageView.builder]
/// with a [SlideDotIndicator] below.
///
/// All data comes from [InternshipPost]. Supports full light and dark themes
/// via [InternshipCarouselColors].
class InternshipCarouselCard extends StatefulWidget {
  final InternshipPost post;
  const InternshipCarouselCard({required this.post, super.key});

  @override
  State<InternshipCarouselCard> createState() => _InternshipCarouselCardState();
}

class _InternshipCarouselCardState extends State<InternshipCarouselCard> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  static const int _totalSlides = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSlide(int index) {
    switch (index) {
      case 0:
        return Slide1Hook(post: widget.post);
      case 1:
        return Slide2Details(post: widget.post);
      case 2:
        return Slide3About(post: widget.post);
      case 3:
        return Slide4Skills(post: widget.post);
      case 4:
        return Slide5CTA(post: widget.post);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _totalSlides,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (page) {
            setState(() => _currentPage = page);
          },
          itemBuilder: (context, index) {
            return _buildSlide(index);
          },
        ),
      ),
    );
  }
}

/// Five-dot slide indicator with animated active pill.
///
/// Active dot: accentCoral, width 20, height 6, pill shape.
/// Inactive dot: mutedText at 40% opacity, 6×6 circle.
class _SlideDotIndicator extends StatelessWidget {
  final int currentPage;
  final int totalSlides;
  const _SlideDotIndicator({
    required this.currentPage,
    required this.totalSlides,
  });

  @override
  Widget build(BuildContext context) {
    final c = InternshipCarouselColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSlides, (index) {
        final isActive = index == currentPage;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: isActive ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? c.accentCoral : c.mutedText.withOpacity(0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
