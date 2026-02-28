
import 'package:flutter/material.dart';
import '../models/filter_model.dart';
import '../services/local_storage_service.dart';

class FilterBottomSheet extends StatefulWidget {
  final String category;
  final FilterModel currentFilters;
  final Function(FilterModel) onApply;
  final VoidCallback onReset;

  const FilterBottomSheet({
    super.key,
    required this.category,
    required this.currentFilters,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterModel _tempFilters;

  // ── Palette Getters ──
  Color _ink(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  Color _muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;
  Color _surface(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color _border(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;
  Color _cardBg(BuildContext context) => Theme.of(context).colorScheme.surface;

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.currentFilters.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _tempFilters.activeCount;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ──
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Header ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Filter icon + title
              Icon(Icons.tune_rounded, size: 18, color: _ink(context)),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink(context),
                  letterSpacing: -0.3,
                ),
              ),
              if (activeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accent(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$activeCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _accent(context),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Reset
              GestureDetector(
                onTap: () {
                  setState(() {
                    _tempFilters = FilterModel();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _border(context), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 13, color: _muted(context)),
                      const SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Scrollable content ──
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════
                  // SORT section
                  // ═══════════════════════════
                  _sectionHeader(context, Icons.swap_vert_rounded, 'Sort'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _sortChip('Newest', SortOption.newest),
                      const SizedBox(width: 8),
                      _sortChip('Oldest', SortOption.oldest),
                      const SizedBox(width: 8),
                      _sortChip('Deadline ↑', SortOption.nearestDeadline),
                      const SizedBox(width: 8),
                      _sortChip('Deadline ↓', SortOption.latestDeadline),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       _sortChip('Serial # (1-9)', SortOption.serialNumberAsc), 
                    ],
                  ),

                  // ═══════════════════════════
                  // CATEGORY FILTERS
                  // ═══════════════════════════
                  _buildCategoryFilters(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Apply button ──
          Row(
            children: [
              // Cancel
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border(context), width: 0.8),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _muted(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Apply
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    widget.onApply(_tempFilters);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: colorScheme.primary,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (activeCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$activeCount',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CATEGORY-SPECIFIC FILTERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildCategoryFilters() {
    if (widget.category == 'Applied' || widget.category == 'Apply Later') {
      return _buildStatusTabFilters();
    } else if (widget.category == 'Internships') {
      return _buildInternshipFilters();
    } else if (widget.category == 'Hackathons') {
      return _buildHackathonFilters();
    } else if (widget.category == 'Events' || widget.category == 'Meetups') {
      return _buildEventFilters();
    }
    return const SizedBox.shrink();
  }

  // ── Status Tabs ──
  Widget _buildStatusTabFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        _sectionHeader(context, Icons.category_outlined, 'Type of Opportunity'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterTag('Internships', Icons.laptop_mac_rounded, _tempFilters.showInternships, (v) => _tempFilters.showInternships = v),
            _filterTag('Hackathons', Icons.code_rounded, _tempFilters.showHackathons, (v) => _tempFilters.showHackathons = v),
            _filterTag('Events', Icons.event_rounded, _tempFilters.showEvents, (v) => _tempFilters.showEvents = v),
            _filterTag('Competitions', Icons.emoji_events_rounded, _tempFilters.showCompetitions, (v) => _tempFilters.showCompetitions = v),
            _filterTag('Meetups', Icons.groups_rounded, _tempFilters.showMeetups, (v) => _tempFilters.showMeetups = v),
          ],
        ),
      ],
    );
  }

  // ── Internship Filters ──
  Widget _buildInternshipFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        _sectionHeader(context, Icons.location_on_outlined, 'Work Mode'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterTag('Remote', Icons.wifi_rounded, _tempFilters.isRemote, (v) => _tempFilters.isRemote = v),
            _filterTag('Hybrid', Icons.sync_alt_rounded, _tempFilters.isHybrid, (v) => _tempFilters.isHybrid = v),
            _filterTag('On-Site', Icons.business_rounded, _tempFilters.isOnSite, (v) => _tempFilters.isOnSite = v),
          ],
        ),
        const SizedBox(height: 18),
        _sectionHeader(context, Icons.payments_outlined, 'Stipend'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterTag('Paid', Icons.check_circle_outline, _tempFilters.isPaid, (v) => _tempFilters.isPaid = v),
            _filterTag('Unpaid', Icons.money_off_rounded, _tempFilters.isUnpaid, (v) => _tempFilters.isUnpaid = v),
          ],
        ),
      ],
    );
  }

  // ── Hackathon Filters ──
  Widget _buildHackathonFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        _sectionHeader(context, Icons.wifi_rounded, 'Mode'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterTag('Online', Icons.language_rounded, _tempFilters.isOnlineHackathon, (v) => _tempFilters.isOnlineHackathon = v),
            _filterTag('Hybrid', Icons.sync_alt_rounded, _tempFilters.isHybridHackathon, (v) => _tempFilters.isHybridHackathon = v),
            _filterTag('Offline', Icons.location_city_rounded, _tempFilters.isOfflineHackathon, (v) => _tempFilters.isOfflineHackathon = v),
          ],
        ),
        const SizedBox(height: 18),
        _sectionHeader(context, Icons.people_outline_rounded, 'Participation'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterTag('Team', Icons.group_rounded, _tempFilters.isTeamAllowed, (v) => _tempFilters.isTeamAllowed = v),
            _filterTag('Solo', Icons.person_rounded, _tempFilters.isSoloAllowed, (v) => _tempFilters.isSoloAllowed = v),
          ],
        ),
        const SizedBox(height: 18),
        _sectionHeader(context, Icons.emoji_events_outlined, 'Prizes'),
        const SizedBox(height: 8),
        _filterTag('Prize Available', Icons.star_outline_rounded, _tempFilters.isPrizeAvailable, (v) => _tempFilters.isPrizeAvailable = v),
      ],
    );
  }

  // ── Event Filters ──
  Widget _buildEventFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        _sectionHeader(context, Icons.wifi_rounded, 'Mode'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterTag('Online', Icons.language_rounded, _tempFilters.isOnlineEvent, (v) => _tempFilters.isOnlineEvent = v),
            _filterTag('In-Person', Icons.location_city_rounded, _tempFilters.isOfflineEvent, (v) => _tempFilters.isOfflineEvent = v),
          ],
        ),
        const SizedBox(height: 18),
        _sectionHeader(context, Icons.confirmation_num_outlined, 'Cost'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterTag('Free', Icons.check_circle_outline, _tempFilters.isFree, (v) => _tempFilters.isFree = v),
            _filterTag('Paid', Icons.payments_outlined, _tempFilters.isPaidEvent, (v) => _tempFilters.isPaidEvent = v),
          ],
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // REUSABLE COMPONENTS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Section header with icon + label
  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _muted(context)),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: _muted(context),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  /// Sort chip (single select)
  Widget _sortChip(String label, SortOption option) {
    final isSelected = _tempFilters.sortBy == option;
    return GestureDetector(
      onTap: () {
        setState(() => _tempFilters.sortBy = option);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _ink(context) : _surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _ink(context) : _border(context),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? _cardBg(context) : _muted(context),
          ),
        ),
      ),
    );
  }

  /// Filter tag with icon (multi select)
  Widget _filterTag(String label, IconData icon, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        setState(() {
          onChanged(!value);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? _accent(context).withValues(alpha: 0.06) : _surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? _accent(context).withValues(alpha: 0.3) : _border(context),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: value ? _accent(context) : _muted(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                color: value ? _accent(context) : _muted(context),
              ),
            ),
            if (value) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_rounded,
                size: 13,
                color: _accent(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
