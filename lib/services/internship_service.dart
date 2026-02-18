import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/internship_details_model.dart';
import '../core/supabase_client.dart';
import 'cache_service.dart';

class InternshipService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  final CacheService _cacheService = CacheService();

  Future<List<InternshipDetailsModel>> fetchInternships({int page = 0, int limit = 20, bool forceRefresh = false}) async {
    try {
      // 1. Try Cache (only for first page to keep it simple, or we can cache all? 
      // Usually caching pagination is tricky. 
      // User said "fetching all... even when app is opened". 
      // So likely we should fetch ALL and cache ALL?
      // The current pagination implementation suggests we fetch in chunks. 
      // If I cache only the first chunk, it might be okay for "instantly visible".
      // Let's cache the first page (limit=20 or whatever default). 
      // Or if the user wants "fetch all", maybe I should remove pagination for the cache part? 
      // "it should fetch all... so that they will be ready to show instantly".
      // I will implement caching for the *first page* specifically, or if page=0.
      
      if (page == 0 && !forceRefresh) {
        final cached = await _cacheService.getInternships();
        if (cached.isNotEmpty) {
          return cached;
        }
      }

      final int start = page * limit;
      final int end = start + limit - 1;

      final response = await _client
          .from('opportunities')
          .select('*, internship_details!inner(*)')
          .eq('type', 'internship')
          .range(start, end); // Apply pagination to parent
          
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        print("📡 [InternshipService] First item keys: ${data.first.keys.toList()}");
        print("📡 [InternshipService] First item serial: ${data.first['type_serial_no']}");
      }
      final List<InternshipDetailsModel> items = data.map((json) => InternshipDetailsModel.fromJson(json)).toList();

      // Save to cache if it's the first page
      if (page == 0 && items.isNotEmpty) {
        await _cacheService.saveInternships(items);
      }

      return items;
    } catch (e) {
      // If fetch fails and we have cache, maybe return cache?
      if (page == 0 && !forceRefresh) {
         final cached = await _cacheService.getInternships();
         if (cached.isNotEmpty) return cached;
      }
      throw 'Failed to fetch internships: $e';
    }
  }

  Future<void> addInternship(InternshipDetailsModel internship) async {
    try {
      // 1. Insert into opportunities (Parent)
      // Only ID and Type are allowed in parent
      final parentResponse = await _client
          .from('opportunities')
          .insert({
            'type': 'internship', 
            // created_at is default now usually, or we can send it
            // 'created_at': DateTime.now().toIso8601String() 
          })
          .select()
          .single();

      final String opportunityId = parentResponse['id'];

      // 2. Insert into internship_details (Child)
      await _client.from('internship_details').insert({
        'opportunity_id': opportunityId,
        'title': internship.title,
        'company': internship.company,
        'description': internship.description,
        'location': internship.location,
        'deadline': internship.deadline.toIso8601String(),
        'emp_type': internship.empType,
        'stipend': internship.stipend,
        'tags': internship.tags,
        'eligibility': internship.eligibility,
        'link': internship.link,
        'is_elite': internship.isElite,
      });
    } catch (e) {
      throw 'Failed to add internship: $e';
    }
  }

  Future<InternshipDetailsModel?> getInternshipById(String opportunityId) async {
    try {
      final response = await _client
          .from('internship_details')
          .select('*')
          .eq('opportunity_id', opportunityId)
          .maybeSingle();

      if (response == null) return null;
      return InternshipDetailsModel.fromJson(response);
    } catch (e) {
      throw 'Failed to fetch internship: $e';
    }
  }
}
