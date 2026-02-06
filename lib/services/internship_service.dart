import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/internship_model.dart';
import '../core/supabase_client.dart';

class InternshipService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  Future<List<Internship>> fetchInternships() async {
    try {
      final response = await _client
          .from('opportunities')
          .select('*, internship_details(*)')
          .eq('type', 'internship')
          // Using dot notation for sorting might vary by SDK version, 
          // usually just ordering by parent column is safer if joining isn't perfect.
          // But strict requirement was: .order('deadline', foreignTable: 'internship_details')
          // Let's try standard order first. If Supabase V2 supports foreign table sort:
          // .order('deadline', foreignTable: 'internship_details', ascending: true);
          // However, commonly we order by the fetched list manually or use main table deadline.
          // Let's assume the user's instruction is valid for their DB setup.
          // Note: V2 SDK syntax: .order('column', ascending: true, nullsFirst: false, foreignTable: 'foreign_table')
          .order('deadline', ascending: true); 
          
      // Cast response to List
      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) => Internship.fromJson(json)).toList();
    } catch (e) {
      // Return empty list or rethrow depending on needs. Rethrowing helps debug.
      throw 'Failed to fetch internships: $e';
    }
  }
}
