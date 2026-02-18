
import '../core/supabase_client.dart';
import '../models/event_details_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class EventService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  final CacheService _cacheService = CacheService();

  Future<List<EventDetailsModel>> fetchEvents({int page = 0, int limit = 20, bool forceRefresh = false}) async {
    try {
      if (page == 0 && !forceRefresh) {
        final cached = await _cacheService.getEvents();
        if (cached.isNotEmpty) return cached;
      }

      final int start = page * limit;
      final int end = start + limit - 1;

      final response = await _client
          .from('opportunities')
          .select('*, event_details!inner(*)')
          .eq('type', 'event')
          .range(start, end);
          
      final List<dynamic> data = response as List<dynamic>;
      final List<EventDetailsModel> items = data.map((json) => EventDetailsModel.fromJson(json)).toList();

      if (page == 0 && items.isNotEmpty) {
        await _cacheService.saveEvents(items);
      }

      return items;
    } catch (e) {
       if (page == 0 && !forceRefresh) {
         final cached = await _cacheService.getEvents();
         if (cached.isNotEmpty) return cached;
      }
      throw 'Failed to fetch events: $e';
    }
  }

  Future<void> addEvent(EventDetailsModel event) async {
    try {
      // 1. Insert into opportunities (Parent)
      final parentResponse = await _client
          .from('opportunities')
          .insert({'type': 'event'})
          .select()
          .single();

      final String opportunityId = parentResponse['id'];

      // 2. Insert into event_details (Child)
      // Note: NOT sending created_at as it wasn't in schema
      await _client.from('event_details').insert({
        'opportunity_id': opportunityId,
        'title': event.title,
        'organiser': event.organiser,
        'description': event.description,
        'venue': event.venue,
        'entry_fee': event.entryFee,
        'start_date': event.startDate.toIso8601String(),
        'end_date': event.endDate.toIso8601String(),
        'location_link': event.locationLink,
        'apply_link': event.applyLink,
        'apply_deadline': event.applyDeadline.toIso8601String(), // Added
      });
    } catch (e) {
      throw 'Failed to add event: $e';
    }
  }

  Future<EventDetailsModel?> getEventById(String opportunityId) async {
    try {
      final response = await _client
          .from('event_details')
          .select('*')
          .eq('opportunity_id', opportunityId)
          .maybeSingle();

      if (response == null) return null;
      return EventDetailsModel.fromJson(response);
    } catch (e) {
      throw 'Failed to fetch event: $e';
    }
  }
}
