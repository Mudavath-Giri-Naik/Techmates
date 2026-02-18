
import '../core/supabase_client.dart';
import '../models/hackathon_details_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class HackathonService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  final CacheService _cacheService = CacheService();

  Future<List<HackathonDetailsModel>> fetchHackathons({int page = 0, int limit = 20, bool forceRefresh = false}) async {
    try {
      if (page == 0 && !forceRefresh) {
        final cached = await _cacheService.getHackathons();
        if (cached.isNotEmpty) return cached;
      }

      final int start = page * limit;
      final int end = start + limit - 1;

      final response = await _client
          .from('opportunities')
          .select('*, hackathon_details!inner(*)')
          .eq('type', 'hackathon')
          .range(start, end);
          
      final List<dynamic> data = response as List<dynamic>;
      final List<HackathonDetailsModel> items = data.map((json) => HackathonDetailsModel.fromJson(json)).toList();

      if (page == 0 && items.isNotEmpty) {
        await _cacheService.saveHackathons(items);
      }

      return items;
    } catch (e) {
      if (page == 0 && !forceRefresh) {
         final cached = await _cacheService.getHackathons();
         if (cached.isNotEmpty) return cached;
      }
      throw 'Failed to fetch hackathons: $e';
    }
  }

  Future<void> addHackathon(HackathonDetailsModel hackathon) async {
    try {
      // 1. Insert into opportunities (Parent)
      final parentResponse = await _client
          .from('opportunities')
          .insert({'type': 'hackathon'})
          .select()
          .single();

      final String opportunityId = parentResponse['id'];

      // 2. Insert into hackathon_details (Child)
      await _client.from('hackathon_details').insert({
        'opportunity_id': opportunityId,
        'title': hackathon.title,
        'company': hackathon.company,
        'team_size': hackathon.teamSize,
        'location': hackathon.location,
        'description': hackathon.description,
        'eligibility': hackathon.eligibility,
        'start_date': hackathon.startDate?.toIso8601String(),
        'end_date': hackathon.endDate?.toIso8601String(),
        'rounds': hackathon.rounds,
        'prizes': hackathon.prizes,
        'deadline': hackathon.deadline.toIso8601String(),
        'link': hackathon.link,
      });
    } catch (e) {
      throw 'Failed to add hackathon: $e';
    }
  }

  Future<HackathonDetailsModel?> getHackathonById(String opportunityId) async {
    try {
      final response = await _client
          .from('hackathon_details')
          .select('*')
          .eq('opportunity_id', opportunityId)
          .maybeSingle();

      if (response == null) return null;
      return HackathonDetailsModel.fromJson(response);
    } catch (e) {
      throw 'Failed to fetch hackathon: $e';
    }
  }
}
