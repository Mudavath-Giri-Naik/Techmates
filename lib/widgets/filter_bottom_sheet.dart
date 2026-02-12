
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

  @override
  void initState() {
    super.initState();
    // Create a copy to modify temporarily
    _tempFilters = widget.currentFilters.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                   // Reset visual state
                   setState(() {
                      _tempFilters = FilterModel(); // Reset to defaults
                   });
                },
                child: const Text('Reset', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const Divider(),
          
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Sort Section
                  _buildSectionTitle('Sort By'),
                  _buildSortOptions(),
                  
                  const SizedBox(height: 16),
                  
                  // 2. Deadline Section
                  _buildSectionTitle('Deadline'),
                  _buildDeadlineOptions(),
                  
                  const SizedBox(height: 16),

                  // 3. Category Specific Section
                  _buildCategorySpecificFilters(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_tempFilters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }

  Widget _buildSortOptions() {
    return Row(
      children: [
        _buildChoiceChip(
          label: 'Newest First',
          selected: _tempFilters.isNewestFirst,
          onSelected: (val) {
             if (val) setState(() => _tempFilters.isNewestFirst = true);
          },
        ),
        const SizedBox(width: 8),
        _buildChoiceChip(
          label: 'Oldest First',
          selected: !_tempFilters.isNewestFirst,
          onSelected: (val) {
            if (val) setState(() => _tempFilters.isNewestFirst = false);
          },
        ),
      ],
    );
  }
  
  Widget _buildDeadlineOptions() {
    return Row(
      children: [
        _buildChoiceChip(
          label: 'Earliest Deadline',
          selected: _tempFilters.isDeadlineAscending,
          onSelected: (val) {
             if (val) setState(() => _tempFilters.isDeadlineAscending = true);
          },
        ),
        const SizedBox(width: 8),
        _buildChoiceChip(
          label: 'Latest Deadline',
          selected: !_tempFilters.isDeadlineAscending,
          onSelected: (val) {
            if (val) setState(() => _tempFilters.isDeadlineAscending = false);
          },
        ),
      ],
    );
  }

  Widget _buildCategorySpecificFilters() {
     // Status tabs show "Type of Opportunity" filter
     if (widget.category == 'Applied' || widget.category == 'Apply Later') {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           _buildSectionTitle('Type of Opportunity'),
           Wrap(
             spacing: 8,
             children: [
               _buildFilterChip('Internships', _tempFilters.showInternships, (v) => _tempFilters.showInternships = v),
               _buildFilterChip('Hackathons', _tempFilters.showHackathons, (v) => _tempFilters.showHackathons = v),
               _buildFilterChip('Events', _tempFilters.showEvents, (v) => _tempFilters.showEvents = v),
               _buildFilterChip('Competitions', _tempFilters.showCompetitions, (v) => _tempFilters.showCompetitions = v),
               _buildFilterChip('Meetups', _tempFilters.showMeetups, (v) => _tempFilters.showMeetups = v),
             ],
           ),
         ],
       );
     }

     if (widget.category == 'Internships') {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           _buildSectionTitle('Type'),
           Wrap(
             spacing: 8,
             children: [
               _buildFilterChip('Remote', _tempFilters.isRemote, (v) => _tempFilters.isRemote = v),
               _buildFilterChip('Hybrid', _tempFilters.isHybrid, (v) => _tempFilters.isHybrid = v),
               _buildFilterChip('On-Site', _tempFilters.isOnSite, (v) => _tempFilters.isOnSite = v),
             ],
           ),
           const SizedBox(height: 16),
           _buildSectionTitle('Stipend'),
           Wrap(
             spacing: 8,
             children: [
               _buildFilterChip('Paid', _tempFilters.isPaid, (v) => _tempFilters.isPaid = v),
               _buildFilterChip('Unpaid', _tempFilters.isUnpaid, (v) => _tempFilters.isUnpaid = v),
             ],
           ),
         ],
       );
     }
     
     if (widget.category == 'Hackathons') {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           _buildSectionTitle('Mode'),
           Wrap(
             spacing: 8,
             children: [
               _buildFilterChip('Online', _tempFilters.isOnlineHackathon, (v) => _tempFilters.isOnlineHackathon = v),
               _buildFilterChip('Hybrid', _tempFilters.isHybridHackathon, (v) => _tempFilters.isHybridHackathon = v), // Added
               _buildFilterChip('Offline', _tempFilters.isOfflineHackathon, (v) => _tempFilters.isOfflineHackathon = v),
             ],
           ),
           const SizedBox(height: 16),
           _buildSectionTitle('Participation'),
           Wrap(
             spacing: 8,
             children: [
               _buildFilterChip('TeamAllowed', _tempFilters.isTeamAllowed, (v) => _tempFilters.isTeamAllowed = v),
               _buildFilterChip('Solo Allowed', _tempFilters.isSoloAllowed, (v) => _tempFilters.isSoloAllowed = v),
             ],
           ),
            const SizedBox(height: 16),
            _buildSectionTitle('Other'),
            _buildFilterChip('Prize Available', _tempFilters.isPrizeAvailable, (v) => _tempFilters.isPrizeAvailable = v),
         ],
       );
     }

     if (widget.category == 'Events' || widget.category == 'Meetups') {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           _buildSectionTitle('Mode'),
           Wrap(
             spacing: 8,
             children: [
               _buildFilterChip('Online', _tempFilters.isOnlineEvent, (v) => _tempFilters.isOnlineEvent = v),
               _buildFilterChip('In-Person', _tempFilters.isOfflineEvent, (v) => _tempFilters.isOfflineEvent = v),
             ],
           ),
           const SizedBox(height: 16),
           _buildSectionTitle('Cost'),
           Wrap(
             spacing: 8,
             children: [
               _buildFilterChip('Free', _tempFilters.isFree, (v) => _tempFilters.isFree = v),
               _buildFilterChip('Paid', _tempFilters.isPaidEvent, (v) => _tempFilters.isPaidEvent = v),
             ],
           ),
         ],
       );
     }

     return const SizedBox.shrink();
  }

  Widget _buildChoiceChip({required String label, required bool selected, required Function(bool) onSelected}) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: selected ? Colors.blue.shade900 : Colors.grey.shade700,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      showCheckmark: false,
    );
  }

  Widget _buildFilterChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: (v) {
        setState(() {
          onChanged(v);
        });
      },
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: value ? Colors.blue.shade900 : Colors.grey.shade700,
        fontWeight: value ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      showCheckmark: false,
    );
  }
}
