
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';

import '../services/internship_service.dart';
import '../services/elite_internship_service.dart';
import 'package:intl/intl.dart';

import '../services/admin_service.dart';
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
import '../services/opportunity_store.dart';
import '../services/user_role_service.dart';
import '../utils/time_ago.dart';
import '../screens/admin/create_opportunity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {

  final InternshipService _internshipService = InternshipService();
  final HackathonService _hackathonService = HackathonService();
  final EventService _eventService = EventService();
  final FilterService _filterService = FilterService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final AdminService _adminService = AdminService();
  final EliteInternshipService _eliteInternshipService = EliteInternshipService();

  // ── Month calendar state ──
  static const List<String> _monthLabels = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
  late int _selectedMonth;
  late int _selectedYear;
  List<InternshipDetailsModel> _eliteInternships = [];
  List<InternshipDetailsModel> _filteredEliteInternships = []; // Added for filtering
  bool _isLoadingElite = false;
  final ScrollController _monthChipScrollController = ScrollController();
  
  // Categories
  final List<String> _categories = [
    'Hackathons',
    'Internships',
    'Events',
    'Apply Later',
    'Applied',
  ];
  
  String _selectedCategory = 'Hackathons';
  
  // Data - now generic
  List<dynamic> _originalItems = []; 
  List<dynamic> _filteredItems = []; 
  final Map<String, int> _categoryCounts = {};
  
  // Cache for raw data to prevent re-fetching
  final Map<String, List<dynamic>> _rawItemsCache = {};
  
  FilterModel _currentFilters = FilterModel();

  bool _isLoading = true;
  String? _errorMessage;

  // Track last update date for real-time checks
  DateTime _lastUpdateDate = DateTime.now();

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
  
  // Highlighting state for notification navigation
  String? _highlightedOpportunityId;
  
  // Pagination State
  int _currentPage = 0;
  static const int _pageSize = 15;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  StreamSubscription<RemoteMessage>? _firebaseMessagingSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register observer
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
    _loadData(); // Initial load for default category
    _preFetchOtherCategories(); // Background pre-fetch for others
    
    // Initialize notification service and listen for clicks
    final notificationService = NotificationService();
    notificationService.init();
    
    // Register callback for in-feed navigation
    notificationService.onNotificationTap = _handleNotificationNavigation;
    
    // notificationService.notificationStream.listen((data) {
    //   _handleNotificationClick(data);
    // });
    
    // Listen for foreground notifications to show a SnackBar/Banner
    _firebaseMessagingSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 [HomeScreen] Foreground message received: ${message.notification?.title}");
      if (message.notification != null && mounted) {
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
                  // Use global handler
                  NotificationService().handleNotificationClick(message);
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
    
    // Listen to store updates
    OpportunityStore.instance.internships.addListener(_onStoreUpdate);
    OpportunityStore.instance.hackathons.addListener(_onStoreUpdate);
    OpportunityStore.instance.events.addListener(_onStoreUpdate);
    

    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = AuthService().user;
    if (user != null) {
      await UserRoleService().fetchAndCacheRole(user.id);
      if (mounted) setState(() {}); // Trigger rebuild to show FAB
    }
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkForDateChange();
    }
  }

  void _checkForDateChange() {
    final now = DateTime.now();
    // Check if the day has changed
    if (now.day != _lastUpdateDate.day || now.month != _lastUpdateDate.month || now.year != _lastUpdateDate.year) {
      debugPrint("📅 Date changed from $_lastUpdateDate to $now. Refreshing UI for accurate days left.");
      
      if (mounted) {
        setState(() {
          _lastUpdateDate = now;
          // Re-apply filters to update any "ends today" or sorting logic
          _applyFilters();
        });
        
        // Optionally, we could force a fetch if we suspect data is stale, 
        // but re-applying filters solves the visible "days left" issue immediately.
        // If users want fresh data, they can pull to refresh.
      }
    }
  }
  
  void _onStoreUpdate() {
    if (mounted && !(_selectedCategory == 'Applied' || _selectedCategory == 'Apply Later')) {
       _updateFromStore();
    }
  }

  Future<void> _preFetchOtherCategories() async {
    // No longer needed as OpportunityStore fetches all.
    // We can just trigger an update to counts if we want.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _firebaseMessagingSubscription?.cancel();
    OpportunityStore.instance.internships.removeListener(_onStoreUpdate);
    OpportunityStore.instance.hackathons.removeListener(_onStoreUpdate);
    OpportunityStore.instance.events.removeListener(_onStoreUpdate);
    _scrollController.dispose();
    _monthChipScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleNotificationNavigation(String opportunityId, String type) async {
    debugPrint("🔔 [HomeScreen] Handling in-feed navigation for: $opportunityId, type: $type");
    
    // 1. Determine target category from type
    String targetCategory = _selectedCategory;
    final t = type.toLowerCase();
    
    if (t.contains('internship')) {
      targetCategory = 'Internships';
    } else if (t.contains('hackathon')) {
      targetCategory = 'Hackathons';
    } else if (t.contains('event')) {
      targetCategory = 'Events';
    } else if (t.contains('meetup')) {
      targetCategory = 'Events'; // Fallback
    } else if (t.contains('competition')) {
      targetCategory = 'Hackathons'; // Fallback
    }
    
    // 2. Switch category if needed
    if (_selectedCategory != targetCategory) {
      debugPrint("   Switching category to $targetCategory");
      _onCategorySelected(targetCategory);
      
      // Wait for data to load
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    
    // 3. Ensure data is loaded
    if (_filteredItems.isEmpty) {
      debugPrint("   Data not loaded, fetching...");
      await _loadData();
    }
    
    // 4. Find item index
    int index = -1;
    for (int attempt = 0; attempt < 3; attempt++) {
      index = _filteredItems.indexWhere((item) {
        if (item is Opportunity) return item.id == opportunityId;
        if (item is InternshipDetailsModel) return item.opportunityId == opportunityId;
        if (item is HackathonDetailsModel) return item.opportunityId == opportunityId;
        if (item is EventDetailsModel) return item.opportunityId == opportunityId;
        return false;
      });
      
      if (index != -1) break;
      
      // If not found, try fetching by ID directly
      if (attempt == 0) {
        debugPrint("   Item not in list, attempting direct fetch...");
        dynamic fetchedItem;
        
        try {
          if (targetCategory == 'Internships') {
            fetchedItem = await _internshipService.getInternshipById(opportunityId);
          } else if (targetCategory == 'Hackathons') {
            fetchedItem = await _hackathonService.getHackathonById(opportunityId);
          } else if (targetCategory == 'Events') {
            fetchedItem = await _eventService.getEventById(opportunityId);
          }
          
          if (fetchedItem != null && mounted) {
            // Add to beginning of list temporarily for highlighting
            setState(() {
              _filteredItems.insert(0, fetchedItem);
              _originalItems.insert(0, fetchedItem);
            });
            index = 0;
            break;
          }
        } catch (e) {
          debugPrint("   Error fetching item: $e");
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 800));
    }
    
    if (index == -1) {
      debugPrint("   ❌ Item not found after attempts");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Opportunity not found in current view")),
        );
      }
      return;
    }
    
    // 5. Scroll to item
    debugPrint("   ✅ Found item at index $index. Scrolling...");
    if (_scrollController.hasClients && mounted) {
      // Calculate offset (approximate card height)
      double offset = index * 260.0;
      
      // Clamp to valid range
      if (offset > _scrollController.position.maxScrollExtent) {
        offset = _scrollController.position.maxScrollExtent;
      }
      
      await _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
    
    // 6. Highlight item
    if (mounted) {
      setState(() {
        _highlightedOpportunityId = opportunityId;
      });
      
      // Clear highlight after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedOpportunityId = null;
          });
        }
      });
    }
  }

/* 
  // Legacy local handling - moved to NotificationService
  void _handleNotificationClick(Map<String, dynamic> data) async {
      ...
  }
*/

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
    final bool isStatusTab = _selectedCategory == 'Applied' || _selectedCategory == 'Apply Later';
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusService = StatusService();
      await statusService.init();

      if (isStatusTab) {
        // Strictly Local for Applied/Apply Later
        final status = _selectedCategory == 'Applied' ? 'applied' : 'must_apply';
        _originalItems = statusService.getItemsByStatus(status);
        _hasMore = false;
        
        setState(() {
          _currentPage = 0;
          _applyFilters();
          _isLoading = false;
        });
      } else {
        // Data from Store
        if (forceRefresh) {
             await OpportunityStore.instance.fetchAll(forceRefresh: true);
             
             if (mounted) {
                UndoNotification.show(
                  context: context,
                  message: "Refreshed",
                  onUndo: () {}, 
                  duration: const Duration(seconds: 2),
                  showUndo: false,
                );
             }
        }
        
        _updateFromStore();
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

  void _updateFromStore() {
      final store = OpportunityStore.instance;
      List<dynamic> items = [];
      
      if (_selectedCategory == 'Internships') {
         items = store.internships.value;
      } else if (_selectedCategory == 'Hackathons') {
         items = store.hackathons.value;
      } else if (_selectedCategory == 'Events') {
         items = store.events.value;
      }
      
      // Filter out applied/later items?
      // The original code did:
      // items = items.where((op) { ... statusService.getStatus(id) == null ... }).toList();
      // I should probably preserve that logic if I want to hide applied items from main feed.
      // Yes, I need to check status service.
      
      // StatusService usage in original code had await statusService.init() before.
      // I can assume it's initialized or I should make _updateFromStore async?
      // Making it async is safer.
      
      _filterAppliedItems(items);
  }

  Future<void> _filterAppliedItems(List<dynamic> items) async {
       final statusService = StatusService();
       await statusService.init();
       
       final filtered = items.where((op) {
           String id = '';
           if (op is Opportunity) {
             id = op.id;
           } else if (op is InternshipDetailsModel) {
             id = op.opportunityId;
           } else if (op is HackathonDetailsModel) {
             id = op.opportunityId;
           } else if (op is EventDetailsModel) {
             id = op.opportunityId;
           }
           return statusService.getStatus(id) == null; 
       }).toList();
       
       if (mounted) {
         setState(() {
           _originalItems = filtered;
           _rawItemsCache[_selectedCategory] = filtered; // Update local cache too/just for legacy refs
           _categoryCounts[_selectedCategory] = filtered.length;
           _hasMore = false; // We fetch all now, so no pagination for "fetching more" in the store logic yet
           _currentPage = 0;
           _applyFilters();
           _isLoading = false;
         });
       }
  }

  void _applyFilters() {
    List<dynamic> filtered = [];
    
    // sorting handled in services mostly, but client filtering needs re-sort if mixed?
    // FilterService sorts too.
    
    if (_selectedCategory == 'Internships') {
       final List<InternshipDetailsModel> input = _originalItems.whereType<InternshipDetailsModel>().toList();
       filtered = _filterService.applyInternshipFilters(input, _currentFilters);

       // Also filter elite internships
       _filteredEliteInternships = _filterService.applyInternshipFilters(_eliteInternships, _currentFilters);
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
       
       // Sort combined items based on current filter sort option (defaults to newest)
       combined.sort((a, b) {
         DateTime aUpdated = DateTime.now();
         DateTime aDeadline = DateTime.now();
         DateTime bUpdated = DateTime.now();
         DateTime bDeadline = DateTime.now();
         int? aSerial;
         int? bSerial;

         if (a is InternshipDetailsModel) {
           aUpdated = a.updatedAt; aDeadline = a.deadline; aSerial = a.typeSerialNo;
         } else if (a is HackathonDetailsModel) {
           aUpdated = a.updatedAt; aDeadline = a.deadline; aSerial = a.typeSerialNo;
         } else if (a is EventDetailsModel) {
           aUpdated = a.updatedAt; aDeadline = a.applyDeadline; aSerial = a.typeSerialNo;
         } else if (a is Opportunity) {
           aUpdated = a.updatedAt; aDeadline = a.deadline; aSerial = a.typeSerialNo;
         }

         if (b is InternshipDetailsModel) {
           bUpdated = b.updatedAt; bDeadline = b.deadline; bSerial = b.typeSerialNo;
         } else if (b is HackathonDetailsModel) {
           bUpdated = b.updatedAt; bDeadline = b.deadline; bSerial = b.typeSerialNo;
         } else if (b is EventDetailsModel) {
           bUpdated = b.updatedAt; bDeadline = b.applyDeadline; bSerial = b.typeSerialNo;
         } else if (b is Opportunity) {
           bUpdated = b.updatedAt; bDeadline = b.deadline; bSerial = b.typeSerialNo;
         }

         // Serial number sorting
         if (_currentFilters.sortBy == SortOption.serialNumberAsc) {
           if (aSerial == null && bSerial == null) return 0;
           if (aSerial == null) return 1;
           if (bSerial == null) return -1;
           return aSerial.compareTo(bSerial);
         }

         // Closed items go to bottom
         final now = DateTime.now();
         final aClosed = aDeadline.isBefore(now) ? 1 : 0;
         final bClosed = bDeadline.isBefore(now) ? 1 : 0;
         if (aClosed != bClosed) return aClosed.compareTo(bClosed);

         switch (_currentFilters.sortBy) {
           case SortOption.newest:
             return bUpdated.compareTo(aUpdated);
           case SortOption.oldest:
             return aUpdated.compareTo(bUpdated);
           case SortOption.nearestDeadline:
             return aDeadline.compareTo(bDeadline);
           case SortOption.latestDeadline:
             return bDeadline.compareTo(aDeadline);
           case SortOption.serialNumberAsc:
             return 0; // handled above
         }
       });
       
       filtered = combined;
       
    } else {
       final List<Opportunity> input = _originalItems.whereType<Opportunity>().toList();
       filtered = _filterService.applyFilters(input, _currentFilters, _selectedCategory);
    }

    final query = _searchQuery.trim();
    if (query.isNotEmpty) {
      debugPrint("🔍 [HomeScreen] Filtering with query: '${query.toLowerCase()}'");

      filtered = filtered.where((item) => _matchesSearchQuery(item, query)).toList();
      _filteredEliteInternships = _filteredEliteInternships
          .where((item) => _matchesSearchQuery(item, query))
          .toList();

      debugPrint(
        "   ✅ Found ${filtered.length} matches in list and ${_filteredEliteInternships.length} in elite internships.",
      );
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  bool _matchesSearchQuery(dynamic item, String query) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return true;

    String title = '';
    String company = '';
    String location = '';
    if (item is InternshipDetailsModel) {
      title = item.title;
      company = item.company;
    } else if (item is HackathonDetailsModel) {
      title = item.title;
      company = item.company;
      location = item.location;
    } else if (item is EventDetailsModel) {
      title = item.title;
      company = item.organiser;
    } else if (item is Opportunity) {
      title = item.title;
      company = item.organization;
    }

    final normalizedTitle = _normalizeSearchText(title);
    final normalizedCompany = _normalizeSearchText(company);
    final normalizedLocation = _normalizeSearchText(location);
    final combined = '$normalizedTitle $normalizedCompany $normalizedLocation';

    if (normalizedTitle.contains(normalizedQuery) ||
        normalizedCompany.contains(normalizedQuery) ||
        normalizedLocation.contains(normalizedQuery)) {
      return true;
    }

    final tokens = normalizedQuery.split(' ').where((t) => t.isNotEmpty);
    return tokens.every(combined.contains);
  }

  String _normalizeSearchText(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isAllTypesSelected() {
    return !_currentFilters.showInternships && 
           !_currentFilters.showHackathons && 
           !_currentFilters.showEvents && 
           !_currentFilters.showCompetitions && 
           !_currentFilters.showMeetups;
  }

  // Navigation History Stack
  final List<String> _navigationStack = ['Hackathons'];

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      // Add to stack if different (avoid duplicates at top)
      if (_navigationStack.isEmpty || _navigationStack.last != category) {
        _navigationStack.add(category);
      }
      _originalItems = [];
      _filteredItems = [];
      _isLoading = true; // Show loading
    });
    _loadData(forceRefresh: false);
    if (category == 'Internships') {
      _fetchEliteInternships();
    }
  }

  // ── Elite Internship Methods ──

  Future<void> _fetchEliteInternships() async {
    setState(() => _isLoadingElite = true);
    try {
      List<InternshipDetailsModel> results;
      if (_selectedMonth == 0) {
        results = await _eliteInternshipService.fetchAllEliteInternships();
      } else {
        results = await _eliteInternshipService.fetchEliteInternships(_selectedYear, _selectedMonth);
      }
      
      if (mounted) {
        setState(() {
          _eliteInternships = results;
          _filteredEliteInternships = results; // Initialize with all results
          _isLoadingElite = false;
          // Apply current filters immediately
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _eliteInternships = [];
          _filteredEliteInternships = [];
          _isLoadingElite = false;
        });
      }
    }
  }

  void _onMonthSelected(int monthIndex) {
    // monthIndex 0 = All. 1..12 = Jan..Dec
    if (monthIndex == _selectedMonth) return;
    setState(() {
      _selectedMonth = monthIndex;
    });
    _fetchEliteInternships();
  }

  // 0 means "All", 1-12 means Jan-Dec
  Widget _buildMonthChips() {
    // Auto-scroll to selected month after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_monthChipScrollController.hasClients) {
        // If 0 (All) is selected, scroll to top. Else scroll to month.
        final targetOffset = _selectedMonth == 0 ? 0.0 : ((_selectedMonth - 1) * 40.0) + 30; // added offset for "All" chip
        _monthChipScrollController.animateTo(
          targetOffset.clamp(0.0, _monthChipScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Container(
      width: 42,
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _monthChipScrollController,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            // "All" chip
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () => _onMonthSelected(0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 36,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedMonth == 0 ? const Color(0xFF1C4D8D) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedMonth == 0 ? const Color(0xFF1C4D8D) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "All",
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: _selectedMonth == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedMonth == 0 ? Colors.white : const Color(0xFF6B7280),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
            // Month chips
            ...List.generate(12, (index) {
              final monthNum = index + 1;
              final isSelected = monthNum == _selectedMonth;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: () => _onMonthSelected(monthNum),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 36,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1C4D8D) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1C4D8D) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _monthLabels[index],
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF6B7280),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLabel() {
    return Container(
      width: 36,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Very light grey
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 3, 
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Internship Calendar 2026",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.verified_rounded, size: 13, color: Colors.blue.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildEliteHeader() {
    if (_selectedMonth == 0) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(18, 6, 18, 4),
        child: Text(
          'All Verified Internships',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            letterSpacing: 0.2,
          ),
        ),
      );
    }
    final monthName = DateFormat.MMMM().format(DateTime(_selectedYear, _selectedMonth));
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
      child: Text(
        'Verified Internships · $monthName $_selectedYear',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildEliteSection(UserRoleService roleService) {
    if (_isLoadingElite) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_filteredEliteInternships.isEmpty) {
      return _buildAnimatedEmptyEliteState();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _filteredEliteInternships.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final id = item.opportunityId;
        final updatedAt = item.updatedAt;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InternshipCard(
              internship: item,
              serialNumber: index + 1,
              isHighlighted: _highlightedOpportunityId == id,
              onEdit: roleService.isSuperAdmin ? () => _handleEdit(item, id) : null,
              onDelete: roleService.isSuperAdmin ? () => _handleDelete(id) : null,
              margin: const EdgeInsets.only(left: 4, right: 16, bottom: 2),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2, bottom: 4),
              child: Text(
                timeAgo(updatedAt),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedEmptyEliteState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 48,
                    color: Colors.blue.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Verified Internships',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'There are no verified opportunities for this month yet. Check back later!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _onOpenFilters() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterBottomSheet(
        category: _selectedCategory,
        currentFilters: _currentFilters,
        onApply: (newFilters) async {
          setState(() {
            _currentFilters = newFilters;
            _isLoading = true; // Show loading immediately
          });
          await _localStorageService.saveFilters(_selectedCategory, newFilters);
          _loadData(forceRefresh: true);
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

  Future<void> _handleEdit(dynamic item, String id) async {
    Map<String, dynamic> data = {};
    String type = 'internship';

    if (item is InternshipDetailsModel) {
      type = 'internship';
      data = item.toJson();
    } else if (item is HackathonDetailsModel) {
      type = 'hackathon';
      data = item.toJson();
    } else if (item is EventDetailsModel) {
      type = 'event';
      data = item.toJson();
      data['date'] = item.startDate.toIso8601String(); 
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateOpportunityScreen(
        initialType: type,
        existingData: data,
        editId: id,
      )),
    );

    if (result == true) {
      _onRefresh();
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      await _adminService.deleteOpportunity(id);
      _onRefresh();
    }
  }

  // Back navigation handling logic
  void _handleBackNavigation() {
     if (_navigationStack.length > 1) {
       setState(() {
         _navigationStack.removeLast();
         _selectedCategory = _navigationStack.last;
         _originalItems = []; 
         _filteredItems = [];
         _isLoading = true;
       });
       _loadData(forceRefresh: false);
     }
  }

  // Search State
  String _searchQuery = '';

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  String _getSearchHintForCategory() {
    switch (_selectedCategory) {
      case 'Hackathons':
        return 'Search title, company, location (e.g. HackMIT Google Bangalore)';
      case 'Internships':
        return 'Search title or company (e.g. SDE Intern Microsoft)';
      case 'Events':
        return 'Search title or organiser (e.g. AI Meetup IEEE)';
      case 'Applied':
      case 'Apply Later':
        return 'Search saved items by title/company';
      default:
        return 'Search...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = _currentFilters.activeCount;
    final roleService = UserRoleService();

    return PopScope(
      canPop: _navigationStack.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: MainLayout(
      title: "Techmates",
      onSearch: _handleSearch, // Pass search callback
      searchHint: _getSearchHintForCategory(),
      floatingActionButton: roleService.canEdit ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateOpportunityScreen()),
          );
          if (result == true) {
             _onRefresh();
          }
        },
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C4D8D),
        elevation: 8,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        child: const Icon(Icons.add_rounded, size: 30, color: Color(0xFF1C4D8D)),
      ) : null,
      child: Column(
        children: [
          // Category Chips + Filter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                   // Filter Icon
                   Padding(
                     padding: const EdgeInsets.only(right: 10.0),
                     child: GestureDetector(
                       onTap: _onOpenFilters,
                       child: AnimatedContainer(
                         duration: const Duration(milliseconds: 200),
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: filterCount > 0 ? const Color(0xFF4B5563) : const Color(0xFFF5F5F5),
                           borderRadius: BorderRadius.circular(10),
                           border: Border.all(
                             color: filterCount > 0 ? const Color(0xFF4B5563) : const Color(0xFFE0E0E0),
                             width: 1,
                           ),
                         ),
                         child: Icon(
                           Icons.tune_rounded,
                           size: 16,
                           color: filterCount > 0 ? Colors.white : const Color(0xFF616161),
                         ),
                       ),
                     ),
                   ),
                   // Chips
                   ..._categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  int? count = _categoryCounts[category];
                  
                  // Use dynamic count for Internships (verified list)
                  if (category == 'Internships' && isSelected) {
                     count = _eliteInternships.length;
                  }

                  return Padding(
                   padding: const EdgeInsets.only(right: 8.0),
                   child: GestureDetector(
                     onTap: () => _onCategorySelected(category),
                     child: AnimatedContainer(
                       duration: const Duration(milliseconds: 200),
                       curve: Curves.easeOut,
                       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                       decoration: BoxDecoration(
                         color: Colors.transparent,
                         borderRadius: BorderRadius.circular(10),
                         border: Border.all(
                           color: isSelected ? const Color(0xFF1C4D8D) : const Color(0xFFE5E5E5),
                           width: 2,
                         ),
                       ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: category,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF1C4D8D) : const Color(0xFF6B7280),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 12.5,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              if (count != null)
                                TextSpan(
                                  text: " ($count)",
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF1C4D8D) : Colors.black,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 12.5,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                     ),
                   ),
                 );
                }),
                ],
              ),
            ),
          ),
          
          // List Area (Internships has special layout)
          // List Area (Internships has special layout)
          Expanded(
            child: _selectedCategory == 'Internships'
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Sidebar (Months + Static Label)
                    Container(
                      width: 42,
                      color: Colors.white,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildMonthChips(),
                          ),
                          _buildVerticalLabel(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4), 
                    Expanded(
                      child: _buildMainList(UserRoleService()),
                    ),
                  ],
                )
              : _buildMainList(UserRoleService()),
          ), 
        ],
      ),
    )); 
  }

  Widget _buildMainList(UserRoleService roleService) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }
    // Logic change: Don't show full empty state if we have Elite items to show in Internships mode
    // If Internships, we ONLY show the elite section (which handles its own empty state).
    // So we never show the global empty state unless we want to handle failures differently.
    // Actually, for Internships, we always return the list with 1 item (the elite section).
    bool isInternships = _selectedCategory == 'Internships';
    
    if (_filteredItems.isEmpty && !isInternships) {
      return _buildEmptyState();
    }
    return Container(
      color: Colors.white,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.blue,
        backgroundColor: Colors.white,
        displacement: 20,
        strokeWidth: 2.5,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          cacheExtent: 2000.0,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: isInternships ? 1 : _filteredItems.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            
            // For Internships, strictly show only the elite section
            if (isInternships) {
              if (index == 0) return _buildEliteSection(roleService);
              return const SizedBox();
            }

            // Regular logic for other categories
            final adjustedIndex = index;

            if (adjustedIndex == _filteredItems.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
            }

            final item = _filteredItems[adjustedIndex];
            final isStatusTab = _selectedCategory == 'Applied' || _selectedCategory == 'Apply Later';
            
            // Determine ID safely
            String id = '';
            if (item is Opportunity) {
              id = item.id;
            } else if (item is InternshipDetailsModel) {
              id = item.opportunityId;
            } else if (item is HackathonDetailsModel) {
              id = item.opportunityId;
            } else if (item is EventDetailsModel) {
              id = item.opportunityId;
            }
            
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
                final currentIndex = adjustedIndex;
                final currentIsStatusTab = isStatusTab;
                
                String status = '';
                String label = '';
                String currentId = id;
                
                  setState(() {
                  _filteredItems.removeAt(adjustedIndex);
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
              child: () {
                int? sn;
                if (item is InternshipDetailsModel) {
                  sn = item.typeSerialNo;
                }
                
                if (adjustedIndex == 0) {
                    debugPrint("🎨 [HomeScreen] Drawing first card. Item: ${item.runtimeType}, Serial: $sn");
                }

                // Get updatedAt for time-ago label
                DateTime updatedAt;
                if (item is InternshipDetailsModel) {
                  updatedAt = item.updatedAt;
                } else if (item is HackathonDetailsModel) {
                  updatedAt = item.updatedAt;
                } else if (item is EventDetailsModel) {
                  updatedAt = item.updatedAt;
                } else if (item is Opportunity) {
                  updatedAt = item.updatedAt;
                } else {
                  updatedAt = DateTime.now();
                }

                final cardWidget = item is InternshipDetailsModel 
                  ? InternshipCard(
                      internship: item, 
                      serialNumber: adjustedIndex + 1,
                      isHighlighted: _highlightedOpportunityId == item.opportunityId,
                      onEdit: roleService.isSuperAdmin ? () => _handleEdit(item, id) : null,
                      onDelete: roleService.isSuperAdmin ? () => _handleDelete(id) : null,
                      margin: _selectedCategory == 'Internships' 
                          ? const EdgeInsets.only(left: 4, right: 16, bottom: 2) 
                          : null,
                    )
                  : item is HackathonDetailsModel
                      ? HackathonCard(
                          hackathon: item, 
                          serialNumber: adjustedIndex + 1,
                          isHighlighted: _highlightedOpportunityId == item.opportunityId,
                          onEdit: roleService.isSuperAdmin ? () => _handleEdit(item, id) : null,
                          onDelete: roleService.isSuperAdmin ? () => _handleDelete(id) : null,
                        )
                      : item is EventDetailsModel
                          ? EventCard(
                              event: item, 
                              serialNumber: adjustedIndex + 1,
                              isHighlighted: _highlightedOpportunityId == item.opportunityId,
                              onEdit: roleService.isSuperAdmin ? () => _handleEdit(item, id) : null,
                              onDelete: roleService.isSuperAdmin ? () => _handleDelete(id) : null,
                            )
                          : OpportunityCard(
                              opportunity: item, 
                              serialNumber: adjustedIndex + 1,
                              isHighlighted: _highlightedOpportunityId == item.id,
                            );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    cardWidget,
                    // Time Ago Label
                    if (!isStatusTab)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 18, 
                        bottom: item is HackathonDetailsModel ? 2 : 12
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          timeAgo(updatedAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: 20,
        strokeWidth: 2.5,
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
                   BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
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
