import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/internship_details_model.dart';
import '../core/supabase_client.dart';

class EliteInternshipService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  /// Fetches internships for a given [year] and [month].
  Future<List<InternshipDetailsModel>> fetchEliteInternships(int year, int month) async {
    try {
      final response = await _client
          .from('internship_details')
          .select('*')
          .eq('year', year)
          .eq('month', month)
          .order('deadline');

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => InternshipDetailsModel.fromJson(json)).toList();
    } catch (e) {
      throw 'Failed to fetch internships: $e';
    }
  }

  /// Fetches all internships regardless of date.
  Future<List<InternshipDetailsModel>> fetchAllEliteInternships() async {
    try {
      final response = await _client
          .from('internship_details')
          .select('*')
          .order('deadline');

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => InternshipDetailsModel.fromJson(json)).toList();
    } catch (e) {
      throw 'Failed to fetch all internships: $e';
    }
  }
}
