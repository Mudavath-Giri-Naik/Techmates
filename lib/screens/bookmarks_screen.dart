
import 'package:flutter/material.dart';
import '../services/bookmark_service.dart';


import '../models/opportunity_model.dart';
import '../models/internship_details_model.dart';
import '../models/hackathon_details_model.dart';
import '../models/event_details_model.dart';

import '../widgets/unified_bookmark_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  List<dynamic> _bookmarks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Internship', 'Hackathon', 'Event', 'Opportunity'

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _bookmarkService.addListener(_onBookmarksChanged);
  }

  @override
  void dispose() {
    _bookmarkService.removeListener(_onBookmarksChanged);
    super.dispose();
  }

  void _onBookmarksChanged() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    // Ensure service is initialized
    await _bookmarkService.init(); 
    if (mounted) {
      setState(() {
        _bookmarks = _bookmarkService.getBookmarks();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredBookmarks() {
    return _bookmarks.where((item) {
      // 1. Filter by Type
      if (_selectedFilter != 'All') {
        bool match = false;
        if (_selectedFilter == 'Internship' && item is InternshipDetailsModel) {
          match = true;
        } else if (_selectedFilter == 'Hackathon' && item is HackathonDetailsModel) {
          match = true;
        } else if (_selectedFilter == 'Event' && item is EventDetailsModel) {
          match = true;
        } else if (_selectedFilter == 'Opportunity' && item is Opportunity) {
          match = true;
        }
        
        if (!match) return false;
      }

      // 2. Filter by Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        String title = '';
        String org = '';
        
        if (item is InternshipDetailsModel) {
          title = item.title;
          org = item.company;
        } else if (item is HackathonDetailsModel) {
          title = item.title;
          org = item.company;
        } else if (item is EventDetailsModel) {
          title = item.title;
          org = item.organiser;
        } else if (item is Opportunity) {
          title = item.title;
          org = item.organization;
        }
        
        if (!title.toLowerCase().contains(query) && !org.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter Bookmarks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['All', 'Internship', 'Hackathon', 'Event'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        Navigator.pop(context);
                      }
                    },
                    selectedColor: Colors.blue.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue.shade800 : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredBookmarks();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Bookmarks",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: _selectedFilter != 'All' ? Colors.blue : Colors.black87),
            onPressed: _showFilterSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bookmarks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "No bookmarks yet",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Save opportunities to view them here later",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search bookmarks...",
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue, width: 1),
                            ),
                          ),
                        ),
                      ),
                      
                      // List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No matches found",
                                      style: TextStyle(color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16), // Bottom padding handled by card margin
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return UnifiedBookmarkCard(
                                    item: item,
                                    onRemove: _loadBookmarks,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
