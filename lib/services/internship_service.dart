import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/internship_details_model.dart';
import '../core/supabase_client.dart';

class InternshipService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  Future<List<InternshipDetailsModel>> fetchInternships({int page = 0, int limit = 20}) async {
    try {
      final int start = page * limit;
      final int end = start + limit - 1;

      final response = await _client
          .from('internship_details')
          .select('*')
          .order('created_at', ascending: false)
          .range(start, end);
          
      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) => InternshipDetailsModel.fromJson(json)).toList();
    } catch (e) {
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
      });
    } catch (e) {
      throw 'Failed to add internship: $e';
    }
  }
}
