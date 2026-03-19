import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import '../services/college_service.dart';
import 'profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<UserProfile> _users = [];
  List<Map<String, dynamic>> _colleges = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _debounce;

  // When a college is selected, show its students
  Map<String, dynamic>? _selectedCollege;
  List<UserProfile> _collegeStudents = [];
  bool _isLoadingCollegeStudents = false;
  
  final CollegeService _collegeService = CollegeService();
  
  @override
  void initState() {
    super.initState();
    _fetchNewMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchNewMembers() async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
      _colleges = [];
      _selectedCollege = null;
    });

    try {
      final response = await SupabaseClientManager.instance
          .from('profiles')
          .select()
          .order('created_at', ascending: false)
          .limit(15);
          
      final List<UserProfile> users = (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
          
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ [SearchScreen] Error fetching new members: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.trim();
        _selectedCollege = null;
        _collegeStudents = [];
      });
      
      if (_searchQuery.isEmpty) {
        _fetchNewMembers();
      } else {
        _performSearch(_searchQuery);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      // Search students and colleges in parallel
      final results = await Future.wait([
        SupabaseClientManager.instance
            .from('profiles')
            .select()
            .ilike('full_name', '%$query%')
            .order('created_at', ascending: false)
            .limit(20),
        _collegeService.searchColleges(query),
      ]);
          
      final List<UserProfile> searchResults = (results[0] as List)
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final List<Map<String, dynamic>> collegeResults =
          results[1] as List<Map<String, dynamic>>;
          
      if (mounted) {
        setState(() {
          _users = searchResults;
          _colleges = collegeResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ [SearchScreen] Error searching: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _users = [];
          _colleges = [];
        });
      }
    }
  }

  Future<void> _onCollegeTap(Map<String, dynamic> college) async {
    final collegeId = college['id'] as String?;
    if (collegeId == null) return;

    setState(() {
      _selectedCollege = college;
      _isLoadingCollegeStudents = true;
      _collegeStudents = [];
    });

    try {
      final response = await SupabaseClientManager.instance
          .from('profiles')
          .select()
          .eq('college_id', collegeId)
          .order('full_name', ascending: true)
          .limit(50);

      final List<UserProfile> students = (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _collegeStudents = students;
          _isLoadingCollegeStudents = false;
        });
      }
    } catch (e) {
      debugPrint("❌ [SearchScreen] Error fetching college students: $e");
      if (mounted) {
        setState(() => _isLoadingCollegeStudents = false);
      }
    }
  }
  
  void _navigateToProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  /// Format year as ordinal: 1 → "1st year", 2 → "2nd year", etc.
  String _formatYear(int? year) {
    if (year == null) return '';
    switch (year) {
      case 1: return '1st year';
      case 2: return '2nd year';
      case 3: return '3rd year';
      default: return '${year}th year';
    }
  }

  /// Format branch to short form: extract parenthesized abbreviation or keep as-is
  String _formatBranch(String? branch) {
    if (branch == null || branch.isEmpty) return '';
    // If branch already looks like an abbreviation (short, uppercase-ish), keep it
    final match = RegExp(r'\(([^)]+)\)').firstMatch(branch);
    if (match != null) return match.group(1)!;
    return branch;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: GoogleFonts.syne(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Input
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainerHighest : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? cs.outlineVariant.withValues(alpha: 0.3) : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: cs.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search students or colleges...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              _searchFocus.unfocus();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Results
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _selectedCollege != null
                  ? _buildCollegeStudentsView(cs, isDark)
                  : _buildSearchResults(cs, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ColorScheme cs, bool isDark) {
    final hasColleges = _colleges.isNotEmpty && _isSearching;
    final hasUsers = _users.isNotEmpty;

    if (!hasColleges && !hasUsers) {
      return _buildEmptyState(cs, isDark);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        // College results section
        if (hasColleges) ...[
          _buildSectionTitle('Colleges', Icons.school_rounded, cs, isDark),
          const SizedBox(height: 8),
          ..._colleges.map((college) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCollegeCard(college, cs, isDark),
          )),
          const SizedBox(height: 16),
        ],

        // Student results section
        _buildSectionTitle(
          _isSearching ? 'Students' : 'Newest Techmates',
          Icons.people_rounded,
          cs,
          isDark,
        ),
        const SizedBox(height: 8),
        if (hasUsers)
          ...List.generate(_users.length, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildUserCard(_users[index], cs, isDark),
          ))
        else if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No students found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCollegeStudentsView(ColorScheme cs, bool isDark) {
    final collegeName = _selectedCollege!['name'] as String? ?? 'College';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back to results bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedCollege = null;
                _collegeStudents = [];
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainerLow : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? cs.outlineVariant.withValues(alpha: 0.2) : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_rounded, size: 18,
                    color: cs.primary),
                  const SizedBox(width: 8),
                  Icon(Icons.school_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      collegeName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_collegeStudents.length} students',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Students list
        Expanded(
          child: _isLoadingCollegeStudents
            ? const Center(child: CircularProgressIndicator())
            : _collegeStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 56,
                        color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No students found at this college',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _collegeStudents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildUserCard(_collegeStudents[index], cs, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, ColorScheme cs, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey[300] : Colors.grey[800],
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isSearching ? Icons.search_off_rounded : Icons.people_alt_outlined,
            size: 64,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No results found' : 'No members found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching ? "Try a different name or college" : "Check back later for new members",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeCard(Map<String, dynamic> college, ColorScheme cs, bool isDark) {
    final name = college['name'] as String? ?? 'Unknown College';
    final code = college['code'] as String?;

    return InkWell(
      onTap: () => _onCollegeTap(college),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? cs.primary.withValues(alpha: 0.2)
                : cs.primary.withValues(alpha: 0.15),
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // College Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school_rounded,
                color: cs.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            
            // College details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (code != null && code.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      code,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Tap indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16, color: cs.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserProfile user, ColorScheme cs, bool isDark) {
    final avatarChar = (user.name != null && user.name!.isNotEmpty) ? user.name![0].toUpperCase() : '?';
    final branch = _formatBranch(user.branch);
    final year = _formatYear(user.year);
    final subtitle = [
      if (branch.isNotEmpty) branch,
      if (year.isNotEmpty) year,
    ].join(' · ');
    
    return InkWell(
      onTap: () => _navigateToProfile(user.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? cs.outlineVariant.withValues(alpha: 0.2) : Colors.grey[200]!,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: () => _navigateToProfile(user.id),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      cs.primary,
                      cs.primary.withAlpha(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipOval(
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: Text(
                              avatarChar,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              avatarChar,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            avatarChar,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (user.name == null || user.name!.isEmpty) ? 'Unknown Techmate' : user.name!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Next Icon
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
