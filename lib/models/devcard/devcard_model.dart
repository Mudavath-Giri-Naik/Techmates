// ─── ContributionDay ────────────────────────────────────────────
class ContributionDay {
  final String date;
  final int count;
  final int level;

  ContributionDay({required this.date, required this.count, required this.level});

  factory ContributionDay.fromCount(String date, int count) {
    int level;
    if (count == 0) {
      level = 0;
    } else if (count <= 3) {
      level = 1;
    } else if (count <= 9) {
      level = 2;
    } else if (count <= 19) {
      level = 3;
    } else {
      level = 4;
    }
    return ContributionDay(date: date, count: count, level: level);
  }

  factory ContributionDay.fromJson(Map<String, dynamic> json) => ContributionDay(
        date: json['date'] as String,
        count: json['count'] as int,
        level: json['level'] as int,
      );

  Map<String, dynamic> toJson() => {'date': date, 'count': count, 'level': level};
}

// ─── LanguageStat ───────────────────────────────────────────────
class LanguageStat {
  final String name;
  final String color;
  final int bytes;
  final double percentage;

  LanguageStat({
    required this.name,
    required this.color,
    required this.bytes,
    required this.percentage,
  });

  factory LanguageStat.fromJson(Map<String, dynamic> json) => LanguageStat(
        name: json['name'] as String,
        color: json['color'] as String? ?? '#8B8B8B',
        bytes: json['bytes'] as int,
        percentage: (json['percentage'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'color': color, 'bytes': bytes, 'percentage': percentage};
}

// ─── FrameworkStat ──────────────────────────────────────────────
class FrameworkStat {
  final String name;
  final int projectCount;
  final String category;

  FrameworkStat({
    required this.name,
    required this.projectCount,
    required this.category,
  });

  factory FrameworkStat.fromJson(Map<String, dynamic> json) => FrameworkStat(
        name: json['name'] as String,
        projectCount: json['projectCount'] as int,
        category: json['category'] as String,
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'projectCount': projectCount, 'category': category};
}

// ─── ProjectAnalysis ────────────────────────────────────────────
class ProjectAnalysis {
  final String name;
  final String? description;
  final int stars;
  final int forks;
  final bool isFork;
  final String repoSource;
  final String? orgName;
  final String? orgLogin;
  final String? primaryLanguage;
  final String? primaryLanguageColor;
  final List<String> frameworks;
  final List<String> topics;
  final int commitCount;
  final DateTime createdAt;
  final DateTime pushedAt;
  final String codeStyle;
  final String codeStyleLabel;
  final int builtInDays;
  final int contributorCount;
  final int readmeLength;
  final String url;

  ProjectAnalysis({
    required this.name,
    this.description,
    required this.stars,
    required this.forks,
    required this.isFork,
    required this.repoSource,
    this.orgName,
    this.orgLogin,
    this.primaryLanguage,
    this.primaryLanguageColor,
    required this.frameworks,
    required this.topics,
    required this.commitCount,
    required this.createdAt,
    required this.pushedAt,
    required this.codeStyle,
    required this.codeStyleLabel,
    required this.builtInDays,
    required this.contributorCount,
    required this.readmeLength,
    required this.url,
  });

  factory ProjectAnalysis.fromJson(Map<String, dynamic> json) => ProjectAnalysis(
        name: json['name'] as String,
        description: json['description'] as String?,
        stars: json['stars'] as int,
        forks: json['forks'] as int,
        isFork: json['isFork'] as bool,
        repoSource: json['repoSource'] as String? ?? 'personal',
        orgName: json['orgName'] as String?,
        orgLogin: json['orgLogin'] as String?,
        primaryLanguage: json['primaryLanguage'] as String?,
        primaryLanguageColor: json['primaryLanguageColor'] as String?,
        frameworks: List<String>.from(json['frameworks'] ?? []),
        topics: List<String>.from(json['topics'] ?? []),
        commitCount: json['commitCount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        pushedAt: DateTime.parse(json['pushedAt'] as String),
        codeStyle: json['codeStyle'] as String,
        codeStyleLabel: json['codeStyleLabel'] as String,
        builtInDays: json['builtInDays'] as int,
        contributorCount: json['contributorCount'] as int,
        readmeLength: json['readmeLength'] as int,
        url: json['url'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'stars': stars,
        'forks': forks,
        'isFork': isFork,
        'repoSource': repoSource,
        'orgName': orgName,
        'orgLogin': orgLogin,
        'primaryLanguage': primaryLanguage,
        'primaryLanguageColor': primaryLanguageColor,
        'frameworks': frameworks,
        'topics': topics,
        'commitCount': commitCount,
        'createdAt': createdAt.toIso8601String(),
        'pushedAt': pushedAt.toIso8601String(),
        'codeStyle': codeStyle,
        'codeStyleLabel': codeStyleLabel,
        'builtInDays': builtInDays,
        'contributorCount': contributorCount,
        'readmeLength': readmeLength,
        'url': url,
      };
}

// ─── CommitActivity ─────────────────────────────────────────────
class CommitActivity {
  final String message;
  final DateTime committedDate;
  final String url;
  final int additions;
  final int deletions;
  final String authorName;
  final String repoName;
  final String repoUrl;

  CommitActivity({
    required this.message,
    required this.committedDate,
    required this.url,
    required this.additions,
    required this.deletions,
    required this.authorName,
    required this.repoName,
    required this.repoUrl,
  });

  factory CommitActivity.fromJson(Map<String, dynamic> json) => CommitActivity(
        message: json['message'] as String? ?? '',
        committedDate: DateTime.parse(json['committedDate'] as String),
        url: json['url'] as String? ?? '',
        additions: json['additions'] as int? ?? 0,
        deletions: json['deletions'] as int? ?? 0,
        authorName: json['authorName'] as String? ?? '',
        repoName: json['repoName'] as String? ?? '',
        repoUrl: json['repoUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'committedDate': committedDate.toIso8601String(),
        'url': url,
        'additions': additions,
        'deletions': deletions,
        'authorName': authorName,
        'repoName': repoName,
        'repoUrl': repoUrl,
      };
}

// ─── ProjectScore ───────────────────────────────────────────────
class ProjectScore {
  final String projectName;
  final int commitScore;
  final int readmeScore;
  final int techScore;
  final double timelineMultiplier;
  final double finalScore;
  final String timelineLabel;
  final int readmeLength;
  final int repoFrameworkCount;
  final int commitCount;

  ProjectScore({
    required this.projectName,
    required this.commitScore,
    required this.readmeScore,
    required this.techScore,
    required this.timelineMultiplier,
    required this.finalScore,
    required this.timelineLabel,
    required this.readmeLength,
    required this.repoFrameworkCount,
    required this.commitCount,
  });

  factory ProjectScore.fromJson(Map<String, dynamic> json) => ProjectScore(
        projectName: json['projectName'] as String,
        commitScore: json['commitScore'] as int,
        readmeScore: json['readmeScore'] as int,
        techScore: json['techScore'] as int,
        timelineMultiplier: (json['timelineMultiplier'] as num).toDouble(),
        finalScore: (json['finalScore'] as num).toDouble(),
        timelineLabel: json['timelineLabel'] as String,
        readmeLength: json['readmeLength'] as int? ?? 0,
        repoFrameworkCount: json['repoFrameworkCount'] as int? ?? 0,
        commitCount: json['commitCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'commitScore': commitScore,
        'readmeScore': readmeScore,
        'techScore': techScore,
        'timelineMultiplier': timelineMultiplier,
        'finalScore': finalScore,
        'timelineLabel': timelineLabel,
        'readmeLength': readmeLength,
        'repoFrameworkCount': repoFrameworkCount,
        'commitCount': commitCount,
      };
}

// ─── DevScoreBreakdown ──────────────────────────────────────────
class DevScoreBreakdown {
  final int depth;
  final int consistency;
  final int breadth;
  final int activity;
  final int total;
  final String rank;
  final String rankEmoji;
  final String rankColor;

  final String depthReason;
  final String consistencyReason;
  final String breadthReason;
  final String activityReason;

  final String depthTip;
  final String consistencyTip;
  final String breadthTip;
  final String activityTip;

  final String topProjectName;
  final int topProjectScore;

  DevScoreBreakdown({
    required this.depth,
    required this.consistency,
    required this.breadth,
    required this.activity,
    required this.total,
    required this.rank,
    required this.rankEmoji,
    required this.rankColor,
    required this.depthReason,
    required this.consistencyReason,
    required this.breadthReason,
    required this.activityReason,
    required this.depthTip,
    required this.consistencyTip,
    required this.breadthTip,
    required this.activityTip,
    required this.topProjectName,
    required this.topProjectScore,
  });

  factory DevScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      DevScoreBreakdown(
        depth: json['depth'] as int? ?? 0,
        consistency: json['consistency'] as int? ?? 0,
        breadth: json['breadth'] as int? ?? 0,
        activity: json['activity'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        rank: json['rank'] as String? ?? 'Beginner',
        rankEmoji: json['rankEmoji'] as String? ?? '🌱',
        rankColor: json['rankColor'] as String? ?? '#9E9E9E',
        depthReason: json['depthReason'] as String? ?? '',
        consistencyReason: json['consistencyReason'] as String? ?? '',
        breadthReason: json['breadthReason'] as String? ?? '',
        activityReason: json['activityReason'] as String? ?? '',
        depthTip: json['depthTip'] as String? ?? '',
        consistencyTip: json['consistencyTip'] as String? ?? '',
        breadthTip: json['breadthTip'] as String? ?? '',
        activityTip: json['activityTip'] as String? ?? '',
        topProjectName: json['topProjectName'] as String? ?? '',
        topProjectScore: json['topProjectScore'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'depth': depth,
        'consistency': consistency,
        'breadth': breadth,
        'activity': activity,
        'total': total,
        'rank': rank,
        'rankEmoji': rankEmoji,
        'rankColor': rankColor,
        'depthReason': depthReason,
        'consistencyReason': consistencyReason,
        'breadthReason': breadthReason,
        'activityReason': activityReason,
        'depthTip': depthTip,
        'consistencyTip': consistencyTip,
        'breadthTip': breadthTip,
        'activityTip': activityTip,
        'topProjectName': topProjectName,
        'topProjectScore': topProjectScore,
      };
}

// ─── DevCardModel ───────────────────────────────────────────────
class DevCardModel {
  final String userId;
  final String githubUsername;
  final String githubAvatarUrl;
  final int totalPublicRepos;
  final int totalStars;
  final int totalCommitsLastYear;
  final int totalPRs;
  final int totalIssues;
  final int currentStreak;
  final int longestStreak;
  final double activeDaysPercentage;
  final List<LanguageStat> topLanguages;
  final List<FrameworkStat> topFrameworks;
  final List<String> personalityTags;
  final List<ContributionDay> heatmapData;
  final List<ProjectAnalysis> projects;
  final List<CommitActivity> recentCommits;
  final List<ProjectScore> projectScores;
  final DevScoreBreakdown scoreBreakdown;
  final DateTime lastFetchedAt;

  DevCardModel({
    required this.userId,
    required this.githubUsername,
    required this.githubAvatarUrl,
    required this.totalPublicRepos,
    required this.totalStars,
    required this.totalCommitsLastYear,
    required this.totalPRs,
    required this.totalIssues,
    required this.currentStreak,
    required this.longestStreak,
    required this.activeDaysPercentage,
    required this.topLanguages,
    required this.topFrameworks,
    required this.personalityTags,
    required this.heatmapData,
    required this.projects,
    required this.recentCommits,
    required this.projectScores,
    required this.scoreBreakdown,
    required this.lastFetchedAt,
  });

  factory DevCardModel.fromJson(Map<String, dynamic> json) => DevCardModel(
        userId: json['userId'] as String,
        githubUsername: json['githubUsername'] as String,
        githubAvatarUrl: json['githubAvatarUrl'] as String? ?? '',
        totalPublicRepos: json['totalPublicRepos'] as int,
        totalStars: json['totalStars'] as int,
        totalCommitsLastYear: json['totalCommitsLastYear'] as int,
        totalPRs: json['totalPRs'] as int,
        totalIssues: json['totalIssues'] as int,
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        activeDaysPercentage: (json['activeDaysPercentage'] as num).toDouble(),
        topLanguages: (json['topLanguages'] as List)
            .map((e) => LanguageStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        topFrameworks: (json['topFrameworks'] as List)
            .map((e) => FrameworkStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        personalityTags: List<String>.from(json['personalityTags'] ?? []),
        heatmapData: (json['heatmapData'] as List)
            .map((e) => ContributionDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        projects: (json['projects'] as List)
            .map((e) => ProjectAnalysis.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentCommits: (json['recentCommits'] as List? ?? [])
            .map((e) => CommitActivity.fromJson(e as Map<String, dynamic>))
            .toList(),
        projectScores: (json['projectScores'] as List? ?? [])
            .map((e) => ProjectScore.fromJson(e as Map<String, dynamic>))
            .toList(),
        scoreBreakdown: DevScoreBreakdown.fromJson(
            json['scoreBreakdown'] as Map<String, dynamic>),
        lastFetchedAt: DateTime.parse(json['lastFetchedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'githubUsername': githubUsername,
        'githubAvatarUrl': githubAvatarUrl,
        'totalPublicRepos': totalPublicRepos,
        'totalStars': totalStars,
        'totalCommitsLastYear': totalCommitsLastYear,
        'totalPRs': totalPRs,
        'totalIssues': totalIssues,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'activeDaysPercentage': activeDaysPercentage,
        'topLanguages': topLanguages.map((e) => e.toJson()).toList(),
        'topFrameworks': topFrameworks.map((e) => e.toJson()).toList(),
        'personalityTags': personalityTags,
        'heatmapData': heatmapData.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'recentCommits': recentCommits.map((e) => e.toJson()).toList(),
        'projectScores': projectScores.map((e) => e.toJson()).toList(),
        'scoreBreakdown': scoreBreakdown.toJson(),
        'lastFetchedAt': lastFetchedAt.toIso8601String(),
      };

  int get totalScore => scoreBreakdown.total;
}
