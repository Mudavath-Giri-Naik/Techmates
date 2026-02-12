
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';
import '../services/opportunity_service.dart';
import '../services/internship_service.dart';
import '../models/opportunity_model.dart';
import '../models/internship_details_model.dart';
import '../widgets/main_layout.dart';
import '../widgets/opportunity_card.dart';
import '../widgets/internship_card.dart';
import '../services/notification_service.dart';
import '../models/filter_model.dart';
import '../services/filter_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../services/status_service.dart';
import '../widgets/undo_notification.dart';

import '../services/event_service.dart';
import '../models/event_details_model.dart';
import '../widgets/event_card.dart';

import '../services/hackathon_service.dart';
import '../models/hackathon_details_model.dart';
import '../widgets/hackathon_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OpportunityService _opportunityService = OpportunityService();
  final InternshipService _internshipService = InternshipService();
  final HackathonService _hackathonService = HackathonService();
  final EventService _eventService = EventService();
  final FilterService _filterService = FilterService();
  final LocalStorageService _localStorageService = LocalStorageService();
  
  // Categories
  final List<String> _categories = [
    'Internships',
    'Hackathons',
    'Events',
    'Apply Later',
    'Applied',
  ];
  
  String _selectedCategory = 'Internships';
  
  // Data - now generic
  List<dynamic> _originalItems = []; 
  List<dynamic> _filteredItems = []; 
  final Map<String, int> _categoryCounts = {};
  
  // Cache for raw data to prevent re-fetching
  final Map<String, List<dynamic>> _rawItemsCache = {};
  
  FilterModel _currentFilters = FilterModel();

  bool _isLoading = true;
  String? _errorMessage;

  void _showUndoNotification(String message, VoidCallback onUndo) {
    if (!mounted) return;
    
    UndoNotification.show(
      context: context,
      message: message,
      onUndo: onUndo,
      duration: const Duration(seconds: 3),
    );
  }

  final ScrollController _scrollController = ScrollController();
  
  // Pagination State
  int _currentPage = 0;
  static const int _pageSize = 15;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadData(); 
    
    // Initialize notification service and listen for clicks
    final notificationService = NotificationService();
    notificationService.init();
    notificationService.notificationStream.listen((data) {
      _handleNotificationClick(data);
    });
    
    // Listen for foreground notifications to show a SnackBar/Banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 [HomeScreen] Foreground message received: ${message.notification?.title}");
      if (message.notification != null) {
        // Show a snackbar or banner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.notification!.title ?? 'New Notification', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(message.notification!.body ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blue.shade900,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                if (message.data.isNotEmpty) {
                  _handleNotificationClick(message.data);
                }
              },
            ),
          ),
        );
      }
    });
    
    // Check if app was launched from notification
    notificationService.checkForInitialMessage();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNotificationClick(Map<String, dynamic> data) async {
    debugPrint("🔔 [HomeScreen] Handling notification click. Payload: $data");
    
    String? opportunityId;
    String? type;
    
    // Strategy 1: Direct keys
    if (data.containsKey('id')) opportunityId = data['id'];
    if (data.containsKey('opportunity_id')) opportunityId = data['opportunity_id'];
    if (data.containsKey('type')) type = data['type'];
    
    // Strategy 2: Nested 'record' string (common in Supabase generic triggers)
    if (opportunityId == null && data.containsKey('record')) {
      try {
        final recordStr = data['record'];
        if (recordStr is String) {
          // It might be a JSON string, need to parse
          // But first, import dart:convert if not imported, or just use regex/simple parsing if simple.
          // It's safer to rely on direct keys if possible, but let's try manual parsing cleanup or assume it's a map if not string.
          // Warning: importing dart:convert might be needed.
        }
      } catch (e) {
        debugPrint("Error parsing record payload: $e");
      }
    }
    
    // Strategy 3: Look for 'title' or 'body' implies it might be just a notification, 
    // but we need ID to navigate.
    
    if (opportunityId == null) {
      debugPrint("❌ [HomeScreen] Could not find opportunity ID in payload. Aborting navigation.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open opportunity. Payload: $data")),
      );
      return;
    }

    debugPrint("✅ [HomeScreen] Target ID: $opportunityId, Type: $type");
      
    // 1. Switch Category if needed
    if (type != null) {
        String targetCategory = _selectedCategory;
        final t = type.toLowerCase();
        
        if (t.contains('internship')) targetCategory = 'Internships';
        else if (t.contains('hackathon')) targetCategory = 'Hackathons';
        else if (t.contains('event')) targetCategory = 'Events';
        else if (t.contains('job') || t.contains('opportunity')) targetCategory = 'Internships'; // Fallback
        
        if (_selectedCategory != targetCategory) {
          debugPrint("   Switching category to $targetCategory");
          _onCategorySelected(targetCategory);
          
          // Wait for data to load
          // _loadData is async, but we don't have a future handle to it easily from here without refactoring.
          // We'll wait a generous amount of time.
          await Future.delayed(const Duration(milliseconds: 1500)); 
        }
    }

    // 2. Find and Scroll
    // Retry logic: logical to try a few times in case loading takes longer
    for (int i = 0; i < 3; i++) {
      int index = _filteredItems.indexWhere((item) {
        if (item is Opportunity) return item.id == opportunityId;
        if (item is InternshipDetailsModel) return item.opportunityId == opportunityId;
        if (item is HackathonDetailsModel) return item.opportunityId == opportunityId;
        if (item is EventDetailsModel) return item.opportunityId == opportunityId;
        return false;
      });

      if (index != -1) {
        debugPrint("   Found item at index $index. Scrolling...");
        
        if (_scrollController.hasClients) {
            double offset = index * 260.0; // Adjusted estimated height
            // Clamp offset
            if (offset > _scrollController.position.maxScrollExtent) {
              offset = _scrollController.position.maxScrollExtent;
            }
            
            _scrollController.animateTo(
              offset, 
              duration: const Duration(seconds: 1), 
              curve: Curves.easeInOut
            );
            
            // Highlight effect? (Optional)
        }
        return; // Success
      }
      
      debugPrint("   Item not found (attempt ${i+1}/3). Waiting...");
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    // If specific item not found, we are at least in the right category.
    debugPrint("   Item still not found in list. It might be on a deeper page.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Opened category. Scroll to find your opportunity!")),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore && _currentFilters.activeCount == 0) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_selectedCategory == 'Applied' || _selectedCategory == 'Apply Later') return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      List<dynamic> newItems = [];

      if (_selectedCategory == 'Internships') {
        newItems = await _internshipService.fetchInternships(page: nextPage, limit: _pageSize);
      } else if (_selectedCategory == 'Hackathons') {
        newItems = await _hackathonService.fetchHackathons(page: nextPage, limit: _pageSize);
      } else if (_selectedCategory == 'Events') {
        newItems = await _eventService.fetchEvents(page: nextPage, limit: _pageSize);
      } else {
        // Other categories not paginated yet or small
        setState(() { _hasMore = false; _isLoadingMore = false; });
        return;
      }

      if (mounted) {
        setState(() {
          if (newItems.isEmpty) {
            _hasMore = false;
          } else {
            _originalItems.addAll(newItems);
            _currentPage = nextPage;
            // Re-apply filters (which just passes through if no filters)
            _applyFilters();
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load more: $e")),
        );
      }
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        if (forceRefresh) {
           _originalItems = [];
           _filteredItems = [];
           _currentPage = 0;
           _hasMore = true;
        }
      });
    }

    try {
      final statusService = StatusService();
      await statusService.init();

      final savedFilters = await _localStorageService.loadFilters(_selectedCategory);
      
      // Determine Mode: Pagination vs Fetch All
      // If filters exist, we fetch ALL (limit 1000) to allow client-side filtering.
      // If no filters, we fetch Page 0.
      final bool isFiltering = savedFilters.activeCount > 0;
      final int limit = isFiltering ? 1000 : _pageSize;

      List<dynamic> items = [];
      int newCount = 0;

      if (_selectedCategory == 'Applied') {
        items = statusService.getItemsByStatus('applied');
      } else if (_selectedCategory == 'Apply Later') {
        items = statusService.getItemsByStatus('must_apply');
      } else {
        // Network Categories
        // We skip cache if we are paginating or filtering extensively to ensure correctness?
        // Actually, for pagination we usually skip cache or manage it complexly.
        // Simplified: Always fetch fresh for pagination.
        
        if (_selectedCategory == 'Internships') {
           items = await _internshipService.fetchInternships(page: 0, limit: limit);
        } else if (_selectedCategory == 'Hackathons') {
           items = await _hackathonService.fetchHackathons(page: 0, limit: limit);
        } else if (_selectedCategory == 'Events') {
           items = await _eventService.fetchEvents(page: 0, limit: limit);
        } else {
           // Others
           final result = await _opportunityService.fetchOpportunities(
             _selectedCategory, 
             forceRefresh: forceRefresh
           );
           items = result.items;
        }
        
        // Exclude status items
        items = items.where((op) {
           String id = '';
           if (op is Opportunity) id = op.id;
           else if (op is InternshipDetailsModel) id = op.opportunityId;
           else if (op is HackathonDetailsModel) id = op.opportunityId;
           else if (op is EventDetailsModel) id = op.opportunityId;
           
           final status = statusService.getStatus(id);
           return status == null; 
        }).toList();
        
        if (forceRefresh) {
           newCount = items.length;
        }
      }

      if (mounted) {
        setState(() {
          _currentFilters = savedFilters;
          _originalItems = items;
          _categoryCounts[_selectedCategory] = items.length; 
          _currentPage = 0;
          
          // If we fetched "All" (limit 1000) or result < pageSize, no more pages
          if (items.length < _pageSize || isFiltering) {
             _hasMore = false;
          } else {
             _hasMore = true;
          }

          _applyFilters();
          
          _isLoading = false;
        });

        if (forceRefresh) {
          final msg = newCount > 0 
              ? "Refreshed"
              : "Refreshed";
          
          UndoNotification.show(
            context: context,
            message: msg,
            onUndo: () {}, 
            duration: const Duration(seconds: 2),
            showUndo: false,
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
            SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _applyFilters() {
    List<dynamic> filtered = [];
    
    // sorting handled in services mostly, but client filtering needs re-sort if mixed?
    // FilterService sorts too.
    
    if (_selectedCategory == 'Internships') {
       final List<InternshipDetailsModel> input = _originalItems.whereType<InternshipDetailsModel>().toList();
       filtered = _filterService.applyInternshipFilters(input, _currentFilters);
    } else if (_selectedCategory == 'Hackathons') {
       final List<HackathonDetailsModel> input = _originalItems.whereType<HackathonDetailsModel>().toList();
       filtered = _filterService.applyHackathonFilters(input, _currentFilters);
    } else if (_selectedCategory == 'Events') {
       final List<EventDetailsModel> input = _originalItems.whereType<EventDetailsModel>().toList();
       filtered = _filterService.applyEventFilters(input, _currentFilters);
    } else if (_selectedCategory == 'Applied' || _selectedCategory == 'Apply Later') {
       // ... existing mixed logic ...
       final internships = _originalItems.whereType<InternshipDetailsModel>().toList();
       final hackathons = _originalItems.whereType<HackathonDetailsModel>().toList();
       final events = _originalItems.whereType<EventDetailsModel>().toList();
       final opportunities = _originalItems.whereType<Opportunity>().toList();
       
       var combined = <dynamic>[];
       
       if (_currentFilters.showInternships || _isAllTypesSelected()) combined.addAll(internships);
       if (_currentFilters.showHackathons || _isAllTypesSelected()) combined.addAll(hackathons);
       if (_currentFilters.showEvents || _isAllTypesSelected()) combined.addAll(events);
       
       final opsFiltered = opportunities.where((op) {
          final t = op.type.toLowerCase();
          if (_currentFilters.showEvents && t.contains('event')) return true;
          if (_currentFilters.showCompetitions && t.contains('competition')) return true;
          if (_currentFilters.showMeetups && t.contains('meetup')) return true;
          if (_currentFilters.showHackathons && t.contains('hackathon')) return true; 
          return _isAllTypesSelected();
       }).toList();
       
       combined.addAll(opsFiltered);
       filtered = combined;
       
    } else {
       final List<Opportunity> input = _originalItems.whereType<Opportunity>().toList();
       filtered = _filterService.applyFilters(input, _currentFilters, _selectedCategory);
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  bool _isAllTypesSelected() {
    return !_currentFilters.showInternships && 
           !_currentFilters.showHackathons && 
           !_currentFilters.showEvents && 
           !_currentFilters.showCompetitions && 
           !_currentFilters.showMeetups;
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _originalItems = [];
      _filteredItems = [];
      _isLoading = true; // Show loading
    });
    _loadData(forceRefresh: false);
  }

  Future<void> _onOpenFilters() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterBottomSheet(
        category: _selectedCategory,
        currentFilters: _currentFilters,
        onApply: (newFilters) {
          setState(() {
            _currentFilters = newFilters;
            _applyFilters();
          });
          _localStorageService.saveFilters(_selectedCategory, newFilters);
        },
        onReset: () {
          setState(() {
            _currentFilters = FilterModel();
            _applyFilters();
          });
           _localStorageService.saveFilters(_selectedCategory, FilterModel());
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _loadData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = _currentFilters.activeCount;

    return MainLayout(
      title: "Techmates", 
      child: Column(
        children: [
          // Category Chips + Filter
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
                     child: GestureDetector(
                       onTap: _onOpenFilters,
                       child: Stack(
                         clipBehavior: Clip.none,
                         children: [
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: filterCount > 0 ? Colors.blue.shade50 : Colors.white,
                               shape: BoxShape.circle,
                               border: Border.all(
                                 color: filterCount > 0 ? Colors.blue.shade200 : Colors.grey.shade300
                               ),
                             ),
                             child: Icon(
                               Icons.tune, 
                               size: 18, 
                               color: filterCount > 0 ? Colors.blue : Colors.grey.shade700
                             ),
                           ),
                         ],
                       ),
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
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
                ],
              ),
            ),
          ),
          
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _errorMessage != null
                    ? Center(child: Text('Error: $_errorMessage'))
                    : _filteredItems.isEmpty
                        ? _buildEmptyState()
                        : Container(
                            color: Colors.white,
                            child: RefreshIndicator(
                              onRefresh: _onRefresh,
                              color: Colors.blue,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                cacheExtent: 2000.0,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _filteredItems.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredItems.length) {
                                     return const Padding(
                                       padding: EdgeInsets.symmetric(vertical: 24.0),
                                       child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                     );
                                  }

                                  final item = _filteredItems[index];
                                  final isStatusTab = _selectedCategory == 'Applied' || _selectedCategory == 'Apply Later';
                                  
                                  // Determine ID safely
                                  String id = '';
                                  if (item is Opportunity) id = item.id;
                                  else if (item is InternshipDetailsModel) id = item.opportunityId;
                                  else if (item is HackathonDetailsModel) id = item.opportunityId;
                                  else if (item is EventDetailsModel) id = item.opportunityId;
                                  
                                  return Dismissible(
                                    key: Key(id),
                                    direction: isStatusTab ? DismissDirection.endToStart : DismissDirection.horizontal,
                                    background: Container(
                                      color: isStatusTab ? Colors.grey : Colors.green,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        children: [
                                          Icon(isStatusTab ? Icons.restore : Icons.check_circle, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text(isStatusTab ? "Restore" : "Applied", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      color: isStatusTab ? Colors.grey : Colors.orange,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(isStatusTab ? "Restore" : "Apply Later", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          Icon(isStatusTab ? Icons.restore : Icons.bookmark, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    onDismissed: (direction) async {
                                      final statusService = StatusService();
                                      
                                      final currentItem = item;
                                      final currentIndex = index;
                                      final currentIsStatusTab = isStatusTab;
                                      
                                      String status = '';
                                      String label = '';
                                      String currentId = id;
                                      
                                        setState(() {
                                        _filteredItems.removeAt(index);
                                        _originalItems.removeWhere((op) {
                                          if (op is Opportunity) return op.id == currentId;
                                          if (op is InternshipDetailsModel) return op.opportunityId == currentId;
                                          if (op is HackathonDetailsModel) return op.opportunityId == currentId;
                                          if (op is EventDetailsModel) return op.opportunityId == currentId;
                                          return false;
                                        });
                                      });

                                      if (currentIsStatusTab) {
                                         await statusService.unmark(currentId);
                                         label = "Restored to feed";
                                      } else {
                                         if (direction == DismissDirection.startToEnd) {
                                           status = 'applied';
                                           label = 'Marked as Applied';
                                         } else {
                                           status = 'must_apply';
                                           label = 'Marked as Apply Later';
                                         }
                                         await statusService.mark(currentItem, status);
                                      }

                                      _showUndoNotification(
                                        label,
                                        () async {
                                          if (currentIsStatusTab) {
                                             if (_selectedCategory == 'Applied') {
                                                await statusService.mark(currentItem, 'applied');
                                             } else if (_selectedCategory == 'Apply Later') {
                                                await statusService.mark(currentItem, 'must_apply');
                                                _showUndoNotification("Item restored to Apply Later list", () {}); // No circular undo needed
                                             }
                                          } else {
                                             await statusService.unmark(currentId);
                                          }
                                          
                                          if (mounted) {
                                            setState(() {
                                              if (currentIndex < _filteredItems.length) {
                                                 _filteredItems.insert(currentIndex, currentItem);
                                              } else {
                                                 _filteredItems.add(currentItem);
                                              }
                                              _originalItems.add(currentItem);
                                            });
                                          }
                                        },
                                      );
                                    },
                                    child: item is InternshipDetailsModel 
                                        ? InternshipCard(internship: item, serialNumber: index + 1)
                                        : item is HackathonDetailsModel
                                            ? HackathonCard(hackathon: item, serialNumber: index + 1)
                                            : item is EventDetailsModel
                                                ? EventCard(event: item, serialNumber: index + 1)
                                                : OpportunityCard(opportunity: item as Opportunity, serialNumber: index + 1),
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
     return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
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
                     "No visible $_selectedCategory match your filters.\nTry resetting filters or Pull down to refresh.",
                     textAlign: TextAlign.center,
                     style: const TextStyle(color: Colors.grey),
                   ),
                   const SizedBox(height: 16),
                   if (_currentFilters.activeCount > 0)
                     TextButton.icon(
                       onPressed: () {
                         setState(() {
                           _currentFilters = FilterModel();
                           _applyFilters();
                         });
                         _localStorageService.saveFilters(_selectedCategory, FilterModel());
                       },
                       icon: const Icon(Icons.clear),
                       label: const Text("Clear Filters"),
                     )
                 ],
               ),
             ),
          ),
        ),
     );
  }
}
