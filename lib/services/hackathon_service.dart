
import '../core/supabase_client.dart';
import '../models/hackathon_details_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HackathonService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  Future<List<HackathonDetailsModel>> fetchHackathons({int page = 0, int limit = 20}) async {
    try {
      final int start = page * limit;
      final int end = start + limit - 1;

      final response = await _client
          .from('hackathon_details')
          .select('*')
          .order('created_at', ascending: false)
          .range(start, end);
          
      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) => HackathonDetailsModel.fromJson(json)).toList();
    } catch (e) {
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
        'rounds': hackathon.rounds,
        'prizes': hackathon.prizes,
        'deadline': hackathon.deadline.toIso8601String(),
        'link': hackathon.link,
      });
    } catch (e) {
      throw 'Failed to add hackathon: $e';
    }
  }
}
