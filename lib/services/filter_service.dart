
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

      // -- Category Specific --
      

      // -- Category Specific --
      // Internships are handled by applyInternshipFilters now.

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
         final hasModeFilter = category == 'Events' 
             ? (filters.isOnlineEvent || filters.isOfflineEvent)
             : (filters.isOnlineEvent || filters.isOfflineEvent); 
         
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
    
    // Default Sort: by Date or Deadline?
    // User requirement: 
    // "SORT: New -> Old (created_at DESC)"
    // "SORT: Old -> New (created_at ASC)"
    // "DEADLINE: Deadline Ascending"
    // "DEADLINE: Deadline Descending"
    
    // We have two sort axes. Usually one overrides distinctively or simple priority.
    // If user selects "New -> Old", we sort by CreatedAt.
    // If user selects "Deadline Asc", we sort by Deadline.
    // Which one takes precedence? 
    // In `FilterModel`, we store them as booleans... wait.
    // `isNewestFirst` is boolean. `isDeadlineAscending` is boolean.
    // This implies toggle states, but maybe they shouldn't be simultaneous primary sorts.
    // The UI usually has radio buttons for "Sort By".
    // "Sort By Date" OR "Sort By Deadline".
    // The Model has `isNewestFirst` which implies Date.
    
    // Let's check `FilterModel` again.
    // I defined:
    // bool isNewestFirst;
    // bool isDeadlineAscending;
    
    // I didn't define a "SortMode" enum.
    // Let's assume priority: Deadline prevails if explicitly set?
    // Actually, usually users want one Primary Sort.
    // Let's act as if they are separate options in the UI sections.
    // The LAST applied sort usually wins in stable sorts.
    
    // Let's interpret:
    // We just return list. Sort is applied at end.
    // We need to know WHICH sort is "Active".
    // Maybe we just sort by Deadline first, then CreatedAt?
    // Let's stick to a robust default:
    // If `isNewestFirst` is TRUE (Default), we sort by created_at DESC.
    // The user requirement said: "SORT: New->Old ... Old->New". This sounds like radio options for Date.
    // And "DEADLINE: Asc ... Desc".
    
    // Let's apply Deadline sort first, then Date if needed? 
    // Actually, Date usually is just for "freshness".
    // Deadline is for "urgency".
    // Use Case: "Show me items ending soonest" -> Deadline ASC.
    // Use Case: "Show me what was just added" -> CreatedAt DESC.
    
    // Since I can't easily change the Model now without rewriting, 
    // I'll implement a logic that respects `isDeadlineAscending` primarily if it's "Active"?
    // Or I'll just apply both in a sensible chain.
    
    // HOWEVER, the standard feed usually sorts by ONE criteria.
    // I'll implement sorting by Deadline primarily because that's crucial for Opportunities.
    // But wait, the requirement says "SORT: New->Old". This implies Date is a major sort.
    
    // Let's refine the logic:
    // We sort by deadline.
    // If deadlines are equal, we sort by created_at.
    
    filtered.sort((a, b) {
      int cmp = 0;
      
      // Primary: Deadline? Or Date?
      // Let's interpret the UI:
      // If user toggles "New->Old", they want Date sort.
      // If user toggles "Deadline Asc/Desc", they want Deadline sort.
      // Since we need to pick one, I will treat Deadline as the PRIMARY sort if the user explicitly changes its default?
      // But `isDeadlineAscending` defaults to true.
      
      // Let's try this:
      // Sort by Deadline (Asc/Desc based on flag)
      // Then tie-break with CreatedAt (New/Old based on flag)
      
      if (filters.isDeadlineAscending) {
        cmp = a.deadline.compareTo(b.deadline);
      } else {
        cmp = b.deadline.compareTo(a.deadline);
      }
      
      if (cmp == 0) {
        if (filters.isNewestFirst) {
          cmp = b.createdAt.compareTo(a.createdAt);
        } else {
          cmp = a.createdAt.compareTo(b.createdAt);
        }
      }
      
      return cmp;
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
      // Logic: (Remote OR Hybrid OR OnSite)
      final hasLocationFilter = filters.isRemote || filters.isHybrid || filters.isOnSite;
      if (hasLocationFilter) {
        bool match = false;
        final modeLower = internship.empType.toLowerCase();
        final locLower = internship.location.toLowerCase();
        
        // Check mode or location for keywords
        if (filters.isRemote && (modeLower.contains('remote') || locLower.contains('remote'))) match = true;
        if (filters.isHybrid && (modeLower.contains('hybrid') || locLower.contains('hybrid'))) match = true;
        if (filters.isOnSite && (modeLower.contains('on-site') || modeLower.contains('office') || (!modeLower.contains('remote') && !modeLower.contains('hybrid')))) match = true; 
        
        if (!match) return false;
      }

      // -- Paid / Unpaid --
      final hasStipendFilter = filters.isPaid || filters.isUnpaid;
      if (hasStipendFilter) {
         bool match = false;
         final stipend = internship.stipend;
         final isPaidItem = stipend > 0;
         final isUnpaidItem = stipend == 0; // or explicitly unpaid text if we had it, but model is int

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
      final now = DateTime.now();
      // Check if closed (deadline passed)
      final aClosed = a.deadline.isBefore(now) ? 1 : 0;
      final bClosed = b.deadline.isBefore(now) ? 1 : 0;
      
      // 1. Primary: Closed items go to bottom
      if (aClosed != bClosed) return aClosed.compareTo(bClosed);

      // 2. Secondary: Existing Logic
      int cmp = 0;
      
      if (filters.isDeadlineAscending) {
        cmp = a.deadline.compareTo(b.deadline);
      } else {
        cmp = b.deadline.compareTo(a.deadline);
      }
      
      if (cmp == 0) {
        if (filters.isNewestFirst) {
          cmp = b.createdAt.compareTo(a.createdAt);
        } else {
          cmp = a.createdAt.compareTo(b.createdAt);
        }
      }
      
      return cmp;
    });

    return filtered;
  }

  // Specialized filter for HackathonDetailsModel
  List<HackathonDetailsModel> applyHackathonFilters(
    List<HackathonDetailsModel> allHackathons, 
    FilterModel filters
  ) {
    var filtered = allHackathons.where((hackathon) {
      // ... existing filter logic ...
      // Online / Offline / Hybrid
      final hasModeFilter = filters.isOnlineHackathon || filters.isOfflineHackathon || filters.isHybridHackathon;
      if (hasModeFilter) {
        bool match = false;
        final locLower = hackathon.location.toLowerCase();
        
        final isOnline = locLower.contains('online') || locLower.contains('remote');
        final isHybrid = locLower.contains('hybrid');
        final isOffline = !isOnline && !isHybrid; 
        
        if (filters.isOnlineHackathon && isOnline) match = true;
        if (filters.isHybridHackathon && isHybrid) match = true;
        if (filters.isOfflineHackathon && isOffline) match = true;
        
        if (!match) return false;
      }

      // Team / Solo
      final teamLower = hackathon.teamSize.toLowerCase();
      // final eligibilityLower = hackathon.eligibility.toLowerCase(); // unused?
      
      if (filters.isTeamAllowed) {
         // Logic: if user wants Team, show if team_size != '1' or 'Solo'
         // Simplified check
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
       final now = DateTime.now();
       final aClosed = a.deadline.isBefore(now) ? 1 : 0;
       final bClosed = b.deadline.isBefore(now) ? 1 : 0;
       
       if (aClosed != bClosed) return aClosed.compareTo(bClosed);
       
       // Default Sort: created_at DESC (Newest First)
       return b.createdAt.compareTo(a.createdAt);
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
       final now = DateTime.now();
       // "Closed" based on apply_deadline
       final aClosed = a.applyDeadline.isBefore(now) ? 1 : 0;
       final bClosed = b.applyDeadline.isBefore(now) ? 1 : 0;
       
       if (aClosed != bClosed) return aClosed.compareTo(bClosed);
       
       
       // 2. Secondary: User Filters
       int cmp = 0;
       
       if (filters.isDeadlineAscending) {
         cmp = a.applyDeadline.compareTo(b.applyDeadline);
       } else {
         cmp = b.applyDeadline.compareTo(a.applyDeadline);
       }
       
       if (cmp == 0) {
         if (filters.isNewestFirst) {
            // Newest (Created most recently)
            cmp = b.createdAt.compareTo(a.createdAt);
         } else {
            cmp = a.createdAt.compareTo(b.createdAt);
         }
       }
       
       return cmp;
    });
    
    return filtered;
  }
}
