import 'package:flutter/material.dart';
import '../services/opportunity_store.dart';
import '../widgets/internship_card.dart';
import '../widgets/hackathon_card.dart';
import '../widgets/event_card.dart';
import '../widgets/opportunity_card.dart';
import '../services/internship_service.dart';
import '../services/hackathon_service.dart';
import '../services/event_service.dart';
import '../models/internship_details_model.dart';
import '../models/hackathon_details_model.dart';
import '../models/event_details_model.dart';
import '../models/opportunity_model.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final String opportunityId;
  final String type;

  const OpportunityDetailScreen({
    super.key,
    required this.opportunityId,
    required this.type,
  });

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  dynamic _item;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    // 1. Try to find in Store first (Sync)
    final store = OpportunityStore.instance;
    dynamic foundItem;

    if (store.internships.value.isNotEmpty) {
      final matches = store.internships.value.where((e) => e.opportunityId == widget.opportunityId);
      if (matches.isNotEmpty) foundItem = matches.first;
    }
    
    if (foundItem == null && store.hackathons.value.isNotEmpty) {
       final matches = store.hackathons.value.where((e) => e.opportunityId == widget.opportunityId);
       if (matches.isNotEmpty) foundItem = matches.first;
    }
    
    if (foundItem == null && store.events.value.isNotEmpty) {
       final matches = store.events.value.where((e) => e.opportunityId == widget.opportunityId);
       if (matches.isNotEmpty) foundItem = matches.first;
    }

    if (foundItem != null) {
      if (mounted) {
        setState(() {
          _item = foundItem;
          _isLoading = false;
        });
      }
      return;
    }

    // 2. If not in store, fetch from Backend (Async)
    try {
      if (widget.type.toLowerCase().contains('internship') || widget.type == 'opportunity') { // Default to internship for 'opportunity' if generic
        final item = await InternshipService().getInternshipById(widget.opportunityId);
        if (item != null) foundItem = item;
      } 
      
      if (foundItem == null && (widget.type.toLowerCase().contains('hackathon'))) {
         final item = await HackathonService().getHackathonById(widget.opportunityId);
         if (item != null) foundItem = item;
      }
      
      if (foundItem == null && (widget.type.toLowerCase().contains('event'))) {
         final item = await EventService().getEventById(widget.opportunityId);
         if (item != null) foundItem = item;
      }
      
      // Fallback: If type was generic 'opportunity' and not found in internship, assert others?
      // For now, trust the 'type' passed. If type is unknown/generic, maybe check all?
      if (foundItem == null && widget.type == 'opportunity') {
         // Try Hackathon
         var hItem = await HackathonService().getHackathonById(widget.opportunityId);
         if (hItem != null) {
           foundItem = hItem;
         } else {
           // Try Event
           var eItem = await EventService().getEventById(widget.opportunityId);
           if (eItem != null) foundItem = eItem;
         }
      }

      if (mounted) {
        if (foundItem != null) {
           setState(() {
             _item = foundItem;
             _isLoading = false;
           });
        } else {
           setState(() {
             _isLoading = false;
             _errorMessage = "Opportunity not available or removed.";
           });
        }
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error fetching details: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_capitalize(widget.type)),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!),
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCard(_item),
                ),
    );
  }

  Widget _buildCard(dynamic item) {
    if (item is InternshipDetailsModel) {
      return InternshipCard(internship: item, serialNumber: null); // No serial for detail view
    } else if (item is HackathonDetailsModel) {
      return HackathonCard(hackathon: item, serialNumber: null);
    } else if (item is EventDetailsModel) {
      return EventCard(event: item, serialNumber: null);
    } else if (item is Opportunity) {
      return OpportunityCard(opportunity: item, serialNumber: null);
    }
    return const Text("Unknown item type");
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
