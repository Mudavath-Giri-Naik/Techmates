
class FilterModel {
  // Sort Orders
  bool isNewestFirst;
  bool isDeadlineAscending; // Default: true (nearest deadline first)

  // Internship Specific
  bool isRemote;
  bool isPaid;
  bool isHybrid;
  bool isOnSite;
  bool isUnpaid;

  // Hackathon Specific
  bool isOnlineHackathon;
  bool isOfflineHackathon;
  bool isHybridHackathon; // Added
  bool isTeamAllowed;
  bool isSoloAllowed;
  bool isPrizeAvailable;

  // Event & Meetup Specific
  bool isOnlineEvent;
  bool isOfflineEvent;
  bool isFree;
  bool isPaidEvent;

  // Common
  bool endsToday;

  // Opportunity Type (for status tabs)
  bool showInternships;
  bool showHackathons;
  bool showEvents;
  bool showCompetitions;
  bool showMeetups;

  FilterModel({
    this.isNewestFirst = true,
    this.isDeadlineAscending = true,
    this.isRemote = false,
    this.isPaid = false,
    this.isHybrid = false,
    this.isOnSite = false,
    this.isUnpaid = false,
    this.isOnlineHackathon = false,
    this.isOfflineHackathon = false,
    this.isHybridHackathon = false, // Added
    this.isTeamAllowed = false,
    this.isSoloAllowed = false,
    this.isPrizeAvailable = false,
    this.isOnlineEvent = false,
    this.isOfflineEvent = false,
    this.isFree = false,
    this.isPaidEvent = false,
    this.endsToday = false,
    this.showInternships = false,
    this.showHackathons = false,
    this.showEvents = false,
    this.showCompetitions = false,
    this.showMeetups = false,
  });

  // Calculate active filter count for the UI badge
  int get activeCount {
    int count = 0;
    
    if (!isNewestFirst) count++;
    if (!isDeadlineAscending) count++;

    if (isRemote) count++;
    if (isPaid) count++;
    if (isHybrid) count++;
    if (isOnSite) count++;
    if (isUnpaid) count++;
    
    if (isOnlineHackathon) count++;
    if (isOfflineHackathon) count++;
    if (isHybridHackathon) count++; // Added
    if (isTeamAllowed) count++;
    if (isSoloAllowed) count++;
    if (isPrizeAvailable) count++;
    
    if (isOnlineEvent) count++;
    if (isOfflineEvent) count++;
    if (isFree) count++;
    if (isPaidEvent) count++;
    
    if (endsToday) count++;
    
    if (showInternships) count++;
    if (showHackathons) count++;
    if (showEvents) count++;
    if (showCompetitions) count++;
    if (showMeetups) count++;
    
    return count;
  }

  // CopyWith for immutability updates if needed (or just mutate since we are local)
  FilterModel copyWith({
    bool? isNewestFirst,
    bool? isDeadlineAscending,
    bool? isRemote,
    bool? isPaid,
    bool? isHybrid,
    bool? isOnSite,
    bool? isUnpaid,
    bool? isOnlineHackathon,
    bool? isOfflineHackathon,
    bool? isHybridHackathon, // Added
    bool? isTeamAllowed,
    bool? isSoloAllowed,
    bool? isPrizeAvailable,
    bool? isOnlineEvent,
    bool? isOfflineEvent,
    bool? isFree,
    bool? isPaidEvent,
    bool? endsToday,
    bool? showInternships,
    bool? showHackathons,
    bool? showEvents,
    bool? showCompetitions,
    bool? showMeetups,
  }) {
    return FilterModel(
      isNewestFirst: isNewestFirst ?? this.isNewestFirst,
      isDeadlineAscending: isDeadlineAscending ?? this.isDeadlineAscending,
      isRemote: isRemote ?? this.isRemote,
      isPaid: isPaid ?? this.isPaid,
      isHybrid: isHybrid ?? this.isHybrid,
      isOnSite: isOnSite ?? this.isOnSite,
      isUnpaid: isUnpaid ?? this.isUnpaid,
      isOnlineHackathon: isOnlineHackathon ?? this.isOnlineHackathon,
      isOfflineHackathon: isOfflineHackathon ?? this.isOfflineHackathon,
      isHybridHackathon: isHybridHackathon ?? this.isHybridHackathon, // Added
      isTeamAllowed: isTeamAllowed ?? this.isTeamAllowed,
      isSoloAllowed: isSoloAllowed ?? this.isSoloAllowed,
      isPrizeAvailable: isPrizeAvailable ?? this.isPrizeAvailable,
      isOnlineEvent: isOnlineEvent ?? this.isOnlineEvent,
      isOfflineEvent: isOfflineEvent ?? this.isOfflineEvent,
      isFree: isFree ?? this.isFree,
      isPaidEvent: isPaidEvent ?? this.isPaidEvent,
      endsToday: endsToday ?? this.endsToday,
      showInternships: showInternships ?? this.showInternships,
      showHackathons: showHackathons ?? this.showHackathons,
      showEvents: showEvents ?? this.showEvents,
      showCompetitions: showCompetitions ?? this.showCompetitions,
      showMeetups: showMeetups ?? this.showMeetups,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isNewestFirst': isNewestFirst,
      'isDeadlineAscending': isDeadlineAscending,
      'isRemote': isRemote,
      'isPaid': isPaid,
      'isHybrid': isHybrid,
      'isOnSite': isOnSite,
      'isUnpaid': isUnpaid,
      'isOnlineHackathon': isOnlineHackathon,
      'isOfflineHackathon': isOfflineHackathon,
      'isHybridHackathon': isHybridHackathon, // Added
      'isTeamAllowed': isTeamAllowed,
      'isSoloAllowed': isSoloAllowed,
      'isPrizeAvailable': isPrizeAvailable,
      'isOnlineEvent': isOnlineEvent,
      'isOfflineEvent': isOfflineEvent,
      'isFree': isFree,
      'isPaidEvent': isPaidEvent,
      'endsToday': endsToday,
      'showInternships': showInternships,
      'showHackathons': showHackathons,
      'showEvents': showEvents,
      'showCompetitions': showCompetitions,
      'showMeetups': showMeetups,
    };
  }

  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(
      isNewestFirst: json['isNewestFirst'] ?? true,
      isDeadlineAscending: json['isDeadlineAscending'] ?? true,
      isRemote: json['isRemote'] ?? false,
      isPaid: json['isPaid'] ?? false,
      isHybrid: json['isHybrid'] ?? false,
      isOnSite: json['isOnSite'] ?? false,
      isUnpaid: json['isUnpaid'] ?? false,
      isOnlineHackathon: json['isOnlineHackathon'] ?? false,
      isOfflineHackathon: json['isOfflineHackathon'] ?? false,
      isHybridHackathon: json['isHybridHackathon'] ?? false, // Added
      isTeamAllowed: json['isTeamAllowed'] ?? false,
      isSoloAllowed: json['isSoloAllowed'] ?? false,
      isPrizeAvailable: json['isPrizeAvailable'] ?? false,
      isOnlineEvent: json['isOnlineEvent'] ?? false,
      isOfflineEvent: json['isOfflineEvent'] ?? false,
      isFree: json['isFree'] ?? false,
      isPaidEvent: json['isPaidEvent'] ?? false,
      endsToday: json['endsToday'] ?? false,
      showInternships: json['showInternships'] ?? false,
      showHackathons: json['showHackathons'] ?? false,
      showEvents: json['showEvents'] ?? false,
      showCompetitions: json['showCompetitions'] ?? false,
      showMeetups: json['showMeetups'] ?? false,
    );
  }
}
