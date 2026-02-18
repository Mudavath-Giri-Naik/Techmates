
import '../models/opportunity_model.dart';
import '../models/filter_model.dart';
import '../models/internship_details_model.dart';
import '../models/hackathon_details_model.dart';
import '../models/event_details_model.dart';

class FilterService {
  
  List<Opportunity> applyFilters(
    List<Opportunity> allOpportunities, 
    FilterModel filters, 
    String category
  ) {
    // 1. Filter
    var filtered = allOpportunities.where((op) {
      
      // Helper to get stipend/mode safely
      String? getStipend(Opportunity o) {
        return o.extraDetails['stipend']?.toString() ?? o.extraDetails['prize_pool']?.toString();
      }
      
      String? getMode(Opportunity o) {
        return o.extraDetails['mode']?.toString() ?? o.location;
      }
      
      String? getEligibility(Opportunity o) {
        return o.extraDetails['eligibility']?.toString();
      }

      // -- Opportunity Type Filter (for status tabs) --
      if (category == 'Applied' || category == 'Apply Later') {
        final hasTypeFilter = filters.showInternships || filters.showHackathons || 
                              filters.showEvents || filters.showCompetitions || filters.showMeetups;
        
        if (hasTypeFilter) {
          bool matchesType = false;
          final typeLower = op.type.toLowerCase();
          
          if (filters.showInternships && typeLower.contains('internship')) matchesType = true;
          if (filters.showHackathons && typeLower.contains('hackathon')) matchesType = true;
          if (filters.showEvents && typeLower.contains('event')) matchesType = true;
          if (filters.showCompetitions && typeLower.contains('competition')) matchesType = true;
          if (filters.showMeetups && typeLower.contains('meetup')) matchesType = true;
          
          if (!matchesType) return false;
        }
      }

      // -- Common Filters --
      // Ends Today
      if (filters.endsToday) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final deadlineDate = DateTime(op.deadline.year, op.deadline.month, op.deadline.day);
        if (deadlineDate != today) return false;
      }

      if (category == 'Hackathons') {
        // Online / Offline
        final hasModeFilter = filters.isOnlineHackathon || filters.isOfflineHackathon;
        if (hasModeFilter) {
          bool match = false;
          final modeLower = (getMode(op) ?? op.location).toLowerCase();
          if (filters.isOnlineHackathon && modeLower.contains('online')) match = true;
          if (filters.isOfflineHackathon && (modeLower.contains('offline') || modeLower.contains('person'))) match = true;
          if (!match) return false;
        }

        // Team / Solo
        final eligibilityLower = (getEligibility(op) ?? '').toLowerCase();
        
        if (filters.isTeamAllowed && !eligibilityLower.contains('team')) {
           if (eligibilityLower.isNotEmpty && !eligibilityLower.contains('team')) {
             if (eligibilityLower.contains('solo only')) return false;
           }
        }
        
        // Prize
        if (filters.isPrizeAvailable) {
          final stipendLower = (getStipend(op) ?? '').toLowerCase();
          if (stipendLower.isEmpty || stipendLower == '0' || stipendLower.contains('no prize')) return false;
        }
      }

      if (category == 'Events' || category == 'Meetups') {
         // Online/Offline
         final hasModeFilter = filters.isOnlineEvent || filters.isOfflineEvent; 
         
         if (hasModeFilter) {
            bool match = false;
            final modeLower = (getMode(op) ?? op.location).toLowerCase();
            if (filters.isOnlineEvent && modeLower.contains('online')) match = true;
            if (filters.isOfflineEvent && (modeLower.contains('offline') || modeLower.contains('person'))) match = true;
            if (!match) return false;
         }

         // Free/Paid
         final hasCostFilter = filters.isFree || filters.isPaidEvent;
         if (hasCostFilter) {
            final costLower = (getStipend(op) ?? '').toLowerCase();
            final isFreeItem = costLower.isEmpty || costLower.contains('free') || costLower == '0';
            final isPaidItem = !isFreeItem;

            if (filters.isFree && isFreeItem) return true; // match
            if (filters.isPaidEvent && isPaidItem) return true; // match
            return false; // neither matched
         }
      }

      return true;
    }).toList();

    // 2. Sort
    filtered.sort((a, b) {
      return _compareItems(
        a.updatedAt, a.deadline, 
        b.updatedAt, b.deadline, 
        filters.sortBy,
        a.typeSerialNo,
        b.typeSerialNo
      );
    });

    return filtered;
  }

  // Specialized filter for InternshipDetailsModel
  List<InternshipDetailsModel> applyInternshipFilters(
    List<InternshipDetailsModel> allInternships, 
    FilterModel filters
  ) {
    // 1. Filter
    var filtered = allInternships.where((internship) {
      
      // -- Location / Mode --
      final hasLocationFilter = filters.isRemote || filters.isHybrid || filters.isOnSite;
      if (hasLocationFilter) {
        bool match = false;
        final modeLower = internship.empType.toLowerCase();
        final locLower = internship.location.toLowerCase();
        
        if (filters.isRemote && (modeLower.contains('remote') || locLower.contains('remote'))) match = true;
        if (filters.isHybrid && (modeLower.contains('hybrid') || locLower.contains('hybrid'))) match = true;
        if (filters.isOnSite && (modeLower.contains('on-site') || modeLower.contains('office') || modeLower.contains('in-person') || (!modeLower.contains('remote') && !modeLower.contains('hybrid')))) match = true; 
        
        if (!match) return false;
      }

      // -- Paid / Unpaid --
      final hasStipendFilter = filters.isPaid || filters.isUnpaid;
      if (hasStipendFilter) {
         bool match = false;
         final stipend = internship.stipend;
         final isPaidItem = stipend > 0;
         final isUnpaidItem = stipend == 0; 

         if (filters.isPaid && isPaidItem) match = true;
         if (filters.isUnpaid && isUnpaidItem) match = true;

         if (!match) return false;
      }
      
      // -- Ends Today --
      if (filters.endsToday) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final deadlineDate = DateTime(internship.deadline.year, internship.deadline.month, internship.deadline.day);
        if (deadlineDate != today) return false;
      }

      return true;
    }).toList();

    // 2. Sort
    filtered.sort((a, b) {
      return _compareItems(
        a.updatedAt, a.deadline, 
        b.updatedAt, b.deadline, 
        filters.sortBy,
        a.typeSerialNo,
        b.typeSerialNo
      );
    });

    return filtered;
  }

  // Specialized filter for HackathonDetailsModel
  List<HackathonDetailsModel> applyHackathonFilters(
    List<HackathonDetailsModel> allHackathons, 
    FilterModel filters
  ) {
    var filtered = allHackathons.where((hackathon) {
      // Online / Offline / Hybrid
      final hasModeFilter = filters.isOnlineHackathon || filters.isOfflineHackathon || filters.isHybridHackathon;
      if (hasModeFilter) {
        bool match = false;
        final locLower = hackathon.location.toLowerCase();
        
        if (filters.isOnlineHackathon && (locLower.contains('online') || locLower.contains('remote'))) match = true;
        if (filters.isHybridHackathon && locLower.contains('hybrid')) match = true;
        if (filters.isOfflineHackathon && (!locLower.contains('online') && !locLower.contains('remote') && !locLower.contains('hybrid'))) match = true;
        
        if (!match) return false;
      }

      // Prize
      if (filters.isPrizeAvailable) {
        final prizesLower = hackathon.prizes.toLowerCase();
        if (prizesLower.isEmpty || prizesLower.contains('no prize') || prizesLower == '0' || prizesLower == 'n/a') return false;
      }
      
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      return _compareItems(
        a.updatedAt, a.deadline, 
        b.updatedAt, b.deadline, 
        filters.sortBy,
        a.typeSerialNo,
        b.typeSerialNo
      );
    });
    
    return filtered;
  }
  
  // Specialized filter for EventDetailsModel
  List<EventDetailsModel> applyEventFilters(
    List<EventDetailsModel> allEvents, 
    FilterModel filters
  ) {
    var filtered = allEvents.where((event) {
      
      // Online / Offline
      final hasModeFilter = filters.isOnlineEvent || filters.isOfflineEvent;
      if (hasModeFilter) {
        bool match = false;
        final venueLower = event.venue.toLowerCase();
        
        if (filters.isOnlineEvent && (venueLower.contains('online') || venueLower.contains('remote'))) match = true;
        if (filters.isOfflineEvent && (!venueLower.contains('online') && !venueLower.contains('remote'))) match = true;
        
        if (!match) return false;
      }

      // Free / Paid
      final hasCostFilter = filters.isFree || filters.isPaidEvent;
      if (hasCostFilter) {
          final fee = event.entryFee?.toLowerCase() ?? '';
          final isFree = fee.isEmpty || fee.contains('free') || fee == '0';
          
          if (filters.isFree && isFree) return true;
          if (filters.isPaidEvent && !isFree) return true;
          
          return false;
      }
      
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      return _compareItems(
        a.updatedAt, eventToDeadline(a), 
        b.updatedAt, eventToDeadline(b), 
        filters.sortBy,
        a.typeSerialNo,
        b.typeSerialNo
      );
    });
    
    return filtered;
  }

  // Helper for Event deadline mapping
  DateTime eventToDeadline(EventDetailsModel e) => e.applyDeadline;

  // Shared comparison logic
  int _compareItems(
    DateTime aCreated, 
    DateTime aDeadline, 
    DateTime bCreated, 
    DateTime bDeadline, 
    SortOption sortBy,
    [int? aSerial, int? bSerial]
  ) {
    final now = DateTime.now();

    // Check serial sorting first
    if (sortBy == SortOption.serialNumberAsc) {
      if (aSerial == null && bSerial == null) return 0;
      if (aSerial == null) return 1; // nulls last
      if (bSerial == null) return -1;
      return aSerial.compareTo(bSerial);
    }
    
    // 1. Check if closed (for items with deadlines)
    final aClosed = aDeadline.isBefore(now) ? 1 : 0;
    final bClosed = bDeadline.isBefore(now) ? 1 : 0;
    
    // Closed items ALWAYS go to the bottom regardless of sort order 
    // (except maybe for "Oldest" but usually it's better this way)
    if (aClosed != bClosed) return aClosed.compareTo(bClosed);

    switch (sortBy) {
      case SortOption.newest:
        return bCreated.compareTo(aCreated);
      case SortOption.oldest:
        return aCreated.compareTo(bCreated);
      case SortOption.nearestDeadline:
        return aDeadline.compareTo(bDeadline);
      case SortOption.latestDeadline:
        return bDeadline.compareTo(aDeadline);
      case SortOption.serialNumberAsc:
        return 0; // handled above
    }
  }
}
