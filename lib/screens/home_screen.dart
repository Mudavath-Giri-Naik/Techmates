import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/opportunity_service.dart';
import '../models/opportunity_model.dart';
import '../widgets/main_layout.dart';
import '../widgets/opportunity_card.dart';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/opportunity_service.dart';
import '../models/opportunity_model.dart';
import '../widgets/main_layout.dart';
import '../widgets/opportunity_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OpportunityService _opportunityService = OpportunityService();
  
  // Categories
  final List<String> _categories = [
    'Internships',
    'Hackathons',
    'Events',
    'Competitions',
    'Meetups',
    'Upcoming',
    'Applied',
  ];
  
  String _selectedCategory = 'Internships';
  List<Opportunity> _opportunities = [];
  final Map<String, int> _categoryCounts = {}; // Track counts for chips
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData(); // Initial load (Cache first)
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    // If not forcing refresh, we show loading spinner initially
    if (!forceRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await _opportunityService.fetchOpportunities(
        _selectedCategory, 
        forceRefresh: forceRefresh
      );

      if (mounted) {
        setState(() {
          _opportunities = result.items;
          _categoryCounts[_selectedCategory] = _opportunities.length; // Update count
          _isLoading = false;
        });

        // Pull-to-Refresh Feedback
        if (forceRefresh) {
          final msg = result.newItemsCount > 0 
              ? "${result.newItemsCount} new opportunities added"
              : "No new opportunities";
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
              backgroundColor: result.newItemsCount > 0 ? Colors.green : Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        if (forceRefresh) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Main Failed: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      // Clear current list to avoid confusion or keep it? 
      // Usually better to show loading for new category
      _opportunities = []; 
      _loadData(forceRefresh: false);
    });
  }

  Future<void> _onRefresh() async {
    await _loadData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Techmates", 
      child: Column(
        children: [
          // Category Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                   // Filter Icon
                   Padding(
                     padding: const EdgeInsets.only(right: 8.0),
                     child: Container(
                       padding: const EdgeInsets.all(6),
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(color: Colors.grey.shade300),
                       ),
                       child: Icon(Icons.tune, size: 16, color: Colors.grey.shade700),
                     ),
                   ),
                   // Chips
                   ..._categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  final count = _categoryCounts[category];
                  final label = count != null ? "$category ($count)" : category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => _onCategorySelected(category),
                      // Custom Flat Styling
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: 1,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue : Colors.grey.shade600,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                      pressElevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false, // Ensure cleaner look? "Colored TEXT + ICON only" usually implies no checkmark if styling text.
                    ),
                  );
                }).toList(),
                ],
              ),
            ),
          ),
          
          // Opportunity List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _errorMessage != null
                    ? Center(child: Text('Error: $_errorMessage'))
                    : _opportunities.isEmpty
                        ? _buildEmptyState()
                        : Container(
                            color: Colors.white,
                            child: RefreshIndicator(
                              onRefresh: _onRefresh,
                              color: Colors.blue,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _opportunities.length,
                                itemBuilder: (context, index) {
                                  return OpportunityCard(
                                    opportunity: _opportunities[index],
                                    serialNumber: index + 1,
                                  );
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     // If empty, we still want RefreshIndicator to allow pulling to try again
     return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6, // Take up space to allow drag
            alignment: Alignment.center,
             child: Container(
               margin: const EdgeInsets.all(32),
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                 ]
               ),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Icon(Icons.search_off, size: 48, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text(
                     "No opportunities found",
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     "No active $_selectedCategory found.\nPull down to refresh.",
                     textAlign: TextAlign.center,
                     style: const TextStyle(color: Colors.grey),
                   ),
                 ],
               ),
             ),
          ),
        ),
     );
  }
}

