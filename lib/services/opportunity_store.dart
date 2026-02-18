import 'package:flutter/foundation.dart';
import '../models/internship_details_model.dart';
import '../models/hackathon_details_model.dart';
import '../models/event_details_model.dart';
import 'internship_service.dart';
import 'hackathon_service.dart';
import 'event_service.dart';

class OpportunityStore {
  // Singleton
  static final OpportunityStore instance = OpportunityStore._privateConstructor();
  OpportunityStore._privateConstructor();

  final InternshipService _internshipService = InternshipService();
  final HackathonService _hackathonService = HackathonService();
  final EventService _eventService = EventService();

  // ValueNotifiers for UI updates
  final ValueNotifier<List<InternshipDetailsModel>> internships = ValueNotifier([]);
  final ValueNotifier<List<HackathonDetailsModel>> hackathons = ValueNotifier([]);
  final ValueNotifier<List<EventDetailsModel>> events = ValueNotifier([]);

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  // timestamps for last fetch to avoid spamming if called multiple times?
  // But we rely on service caching mostly.

  Future<void> fetchAll({bool forceRefresh = false}) async {
    isLoading.value = true;
    error.value = null;

    try {
      // Run in parallel
      await Future.wait([
        _fetchInternships(forceRefresh),
        _fetchHackathons(forceRefresh),
        _fetchEvents(forceRefresh),
      ]);
    } catch (e) {
      debugPrint("Error fetching all opportunities: $e");
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchInternships(bool forceRefresh) async {
    try {
      final items = await _internshipService.fetchInternships(page: 0, limit: 100, forceRefresh: forceRefresh);
      internships.value = items;
    } catch (e) {
      debugPrint("Error fetching internships: $e");
      // Don't rethrow to allow partial success?
    }
  }

  Future<void> _fetchHackathons(bool forceRefresh) async {
    try {
      final items = await _hackathonService.fetchHackathons(page: 0, limit: 100, forceRefresh: forceRefresh);
      hackathons.value = items;
    } catch (e) {
      debugPrint("Error fetching hackathons: $e");
    }
  }

  Future<void> _fetchEvents(bool forceRefresh) async {
    try {
      final items = await _eventService.fetchEvents(page: 0, limit: 100, forceRefresh: forceRefresh);
      events.value = items;
    } catch (e) {
      debugPrint("Error fetching events: $e");
    }
  }
}
