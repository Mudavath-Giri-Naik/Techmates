import 'dart:convert';
import 'dart:math' as math;

import '../../models/devcard/devcard_model.dart';

class DevCardAnalyzer {
  static DevCardModel analyze(Map<String, dynamic> raw, String userId) {
    final user = raw['user'] as Map<String, dynamic>? ?? {};
    final username = user['login'] as String? ?? '';
    final avatarUrl = user['avatarUrl'] as String? ?? '';
    final accountCreatedAt =
        DateTime.tryParse(user['createdAt'] as String? ?? '') ?? DateTime.now();
    final repos = (user['repositories'] as Map<String, dynamic>?)?['nodes']
            as List<dynamic>? ??
        [];
    final contribs =
        user['contributionsCollection'] as Map<String, dynamic>? ?? {};

    // ── Totals ────────────────────────────────────────────────
    final totalRepos =
        (user['repositories'] as Map<String, dynamic>?)?['totalCount']
                as int? ??
            repos.length;
    final totalCommits = contribs['totalCommitContributions'] as int? ?? 0;
    final totalPRs = contribs['totalPullRequestContributions'] as int? ?? 0;
    final totalIssues = contribs['totalIssueContributions'] as int? ?? 0;

    // ── Language Stats ────────────────────────────────────────
    final langMap = <String, _LangAccum>{};
    for (final repo in repos) {
      final r = repo as Map<String, dynamic>;
      if (r['isFork'] == true) continue;
      final edges =
          (r['languages'] as Map<String, dynamic>?)?['edges'] as List? ?? [];
      for (final edge in edges) {
        final e = edge as Map<String, dynamic>;
        final node = e['node'] as Map<String, dynamic>;
        final name = node['name'] as String;
        final color = node['color'] as String? ?? '#8B8B8B';
        final size = e['size'] as int? ?? 0;
        langMap.putIfAbsent(name, () => _LangAccum(name, color));
        langMap[name]!.bytes += size;
      }
    }
    final langList = langMap.values.toList()
      ..sort((a, b) => b.bytes.compareTo(a.bytes));
    final topLangs = langList.take(5).toList();
    final totalBytes = topLangs.fold<int>(0, (s, l) => s + l.bytes);
    final topLanguages = topLangs
        .map((l) => LanguageStat(
              name: l.name,
              color: l.color,
              bytes: l.bytes,
              percentage: totalBytes > 0 ? l.bytes / totalBytes : 0.0,
            ))
        .toList();

    // ── Total Stars ───────────────────────────────────────────
    int totalStars = 0;
    for (final repo in repos) {
      totalStars +=
          (repo as Map<String, dynamic>)['stargazerCount'] as int? ?? 0;
    }

    // ── Framework Detection (global, top 20 non-fork repos) ──
    final fwCounts = <String, _FwAccum>{};
    final reposSortedByPush = List<Map<String, dynamic>>.from(
        repos.map((e) => e as Map<String, dynamic>))
      ..sort((a, b) => (b['pushedAt'] as String? ?? '')
          .compareTo(a['pushedAt'] as String? ?? ''));
    final reposForFw =
        reposSortedByPush.where((r) => r['isFork'] != true).take(20);

    for (final r in reposForFw) {
      final detected = _detectFrameworks(r);
      for (final fw in detected.entries) {
        fwCounts.putIfAbsent(fw.key, () => _FwAccum(fw.key, fw.value));
        fwCounts[fw.key]!.count++;
      }
    }

    final fwList = fwCounts.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final topFrameworks = fwList
        .take(8)
        .map((f) =>
            FrameworkStat(name: f.name, projectCount: f.count, category: f.category))
        .toList();

    // ── Projects Analysis ─────────────────────────────────────
    final projectsList = <ProjectAnalysis>[];
    for (final repo in repos) {
      final r = repo as Map<String, dynamic>;
      final name = r['name'] as String? ?? '';
      final isFork = r['isFork'] as bool? ?? false;
      final repoSource =
          r['repoSource'] as String? ?? (isFork ? 'fork' : 'personal');
      final orgNameVal = r['orgName'] as String?;
      final orgLoginVal = r['orgLogin'] as String?;
      final stars = r['stargazerCount'] as int? ?? 0;
      final forks = r['forkCount'] as int? ?? 0;
      final plNode = r['primaryLanguage'] as Map<String, dynamic>?;
      final createdAtStr =
          r['createdAt'] as String? ?? DateTime.now().toIso8601String();
      final pushedAtStr = r['pushedAt'] as String? ?? createdAtStr;
      final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
      final pushedAt = DateTime.tryParse(pushedAtStr) ?? createdAt;
      final defaultBranch = r['defaultBranchRef'] as Map<String, dynamic>?;
      final historyTarget = defaultBranch?['target'] as Map<String, dynamic>?;
      final commitCount =
          (historyTarget?['history'] as Map<String, dynamic>?)?['totalCount']
                  as int? ??
              0;
      final mentionableCount =
          (r['mentionableUsers'] as Map<String, dynamic>?)?['totalCount']
                  as int? ??
              1;
      final readmeLength =
          ((r['object_readme'] as Map<String, dynamic>?)?['text'] as String?)
                  ?.length ??
              0;
      final builtInDays = math.max(1, pushedAt.difference(createdAt).inDays);

      final topicNodes =
          (r['repositoryTopics'] as Map<String, dynamic>?)?['nodes']
                  as List? ??
              [];
      final topics = topicNodes
          .map((t) =>
              ((t as Map<String, dynamic>)['topic']
                      as Map<String, dynamic>?)?['name'] as String? ??
              '')
          .where((t) => t.isNotEmpty)
          .toList();

      final repoFrameworks = _detectFrameworks(r).keys.toList();

      String codeStyle;
      String codeStyleLabel;
      if (isFork) {
        codeStyle = 'forked';
        codeStyleLabel = '📋 Forked';
      } else if (mentionableCount > 1) {
        codeStyle = 'collaborative';
        codeStyleLabel = '🤝 Collaborative';
      } else if (commitCount >= 20 && builtInDays >= 14 && readmeLength >= 100) {
        codeStyle = 'self_built';
        codeStyleLabel = '🧠 Self-Built';
      } else if (commitCount >= 5 && builtInDays <= 7) {
        codeStyle = 'rapid_build';
        codeStyleLabel = '⚡ Rapid Build';
      } else if (commitCount <= 4) {
        codeStyle = 'vibe_coded';
        codeStyleLabel = '🎨 Vibe Coded';
      } else {
        codeStyle = 'rapid_build';
        codeStyleLabel = '⚡ Rapid Build';
      }

      projectsList.add(ProjectAnalysis(
        name: name,
        description: r['description'] as String?,
        stars: stars,
        forks: forks,
        isFork: isFork,
        repoSource: repoSource,
        orgName: orgNameVal,
        orgLogin: orgLoginVal,
        primaryLanguage: plNode?['name'] as String?,
        primaryLanguageColor: plNode?['color'] as String?,
        frameworks: repoFrameworks,
        topics: topics,
        commitCount: commitCount,
        createdAt: createdAt,
        pushedAt: pushedAt,
        codeStyle: codeStyle,
        codeStyleLabel: codeStyleLabel,
        builtInDays: builtInDays,
        contributorCount: mentionableCount,
        readmeLength: readmeLength,
        url: r['url'] as String? ?? 'https://github.com/$username/$name',
      ));
    }

    projectsList.sort((a, b) => b.pushedAt.compareTo(a.pushedAt));

    // ── Contribution Calendar ─────────────────────────────────
    final calendar =
        contribs['contributionCalendar'] as Map<String, dynamic>? ?? {};
    final weeks = calendar['weeks'] as List<dynamic>? ?? [];
    final heatmapData = <ContributionDay>[];
    for (final week in weeks) {
      final days =
          (week as Map<String, dynamic>)['contributionDays'] as List? ?? [];
      for (final day in days) {
        final d = day as Map<String, dynamic>;
        heatmapData.add(ContributionDay.fromCount(
          d['date'] as String? ?? '',
          d['contributionCount'] as int? ?? 0,
        ));
      }
    }

    // ── Streak Calculation ────────────────────────────────────
    final sortedDesc = List<ContributionDay>.from(heatmapData)
      ..sort((a, b) => b.date.compareTo(a.date));

    int currentStreak = 0;
    for (final day in sortedDesc) {
      if (day.count > 0) {
        currentStreak++;
      } else {
        break;
      }
    }

    int longestStreak = 0;
    int tempStreak = 0;
    for (final day in heatmapData) {
      if (day.count > 0) {
        tempStreak++;
        if (tempStreak > longestStreak) longestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }
    }

    final activeDays = heatmapData.where((d) => d.count > 0).length;
    final activeDaysPercentage =
        heatmapData.isNotEmpty ? activeDays / heatmapData.length : 0.0;

    // ── Recent Commits ────────────────────────────────────────
    final rawCommits = user['recentCommits'] as List<dynamic>? ?? [];
    final recentCommits = rawCommits.take(10).map((c) {
      final cm = c as Map<String, dynamic>;
      final fullMsg = cm['message'] as String? ?? '';
      final firstLine = fullMsg.split('\n').first.trim();
      return CommitActivity(
        message: firstLine,
        committedDate:
            DateTime.tryParse(cm['committedDate'] as String? ?? '') ??
                DateTime.now(),
        url: cm['url'] as String? ?? '',
        additions: cm['additions'] as int? ?? 0,
        deletions: cm['deletions'] as int? ?? 0,
        authorName: cm['authorName'] as String? ?? '',
        repoName: cm['repoName'] as String? ?? '',
        repoUrl: cm['repoUrl'] as String? ?? '',
      );
    }).toList();

    // ── Dev Score ─────────────────────────────────────────────

    // STEP 1: Score ALL non-fork, non-archived repos — no threshold
    // Works for 1 repo, 2 repos, 50 repos — always fair
    final allProjectScores = <ProjectScore>[];
    for (final proj in projectsList) {
      if (proj.isFork) continue;
      final isArchived = repos.any((r) =>
          (r as Map<String, dynamic>)['name'] == proj.name &&
          r['isArchived'] == true);
      if (isArchived) continue;

      // commitScore: 1.5 pts per commit, capped at 50
      final cScore = math.min(50, (proj.commitCount * 1.5).round());

      // readmeScore: tiered
      final rScore = proj.readmeLength >= 500
          ? 25
          : proj.readmeLength >= 100
              ? 12
              : 0;

      // techScore: 6 pts per framework, capped at 24
      final fwCount = proj.frameworks.length;
      final tScore = math.min(24, fwCount * 6);

      // timelineMultiplier based on build duration
      final days = proj.builtInDays;
      double tlMultiplier;
      String tlLabel;
      if (days >= 30) {
        tlMultiplier = 1.0;
        tlLabel = 'Built over $days days';
      } else if (days >= 7) {
        tlMultiplier = 0.7;
        tlLabel = 'Built over $days days';
      } else if (days >= 2) {
        tlMultiplier = 0.4;
        tlLabel = 'Built in $days days';
      } else {
        tlMultiplier = 0.2;
        tlLabel = 'Built in 1 day';
      }

      final fScore = (cScore + rScore + tScore) * tlMultiplier;

      allProjectScores.add(ProjectScore(
        projectName: proj.name,
        commitScore: cScore,
        readmeScore: rScore,
        techScore: tScore,
        timelineMultiplier: tlMultiplier,
        finalScore: fScore,
        timelineLabel: tlLabel,
        readmeLength: proj.readmeLength,
        repoFrameworkCount: fwCount,
        commitCount: proj.commitCount,
      ));
    }
    allProjectScores.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    // STEP 2: Depth score
    // N = min(5, however many repos exist) — always fair
    // 1 repo → uses that 1. 50 repos → uses best 5.
    final totalScoredRepos = allProjectScores.length;
    final n = math.min(5, totalScoredRepos);
    int depthScore;
    ProjectScore? topProject;

    if (n == 0) {
      depthScore = 0;
      topProject = null;
    } else {
      final topN = allProjectScores.take(n).toList();
      final avg =
          topN.fold<double>(0.0, (s, p) => s + p.finalScore) / n;
      depthScore = math.min(100, avg.round());
      topProject = topN.first;
    }

    // STEP 3: Consistency score
    final consistencyScore =
        math.min(100, (activeDaysPercentage * 100).round());

    // STEP 4: Breadth score
    final uniqueLangs = langMap.length;
    final uniqueFrameworksCount = fwCounts.length;
    final languageScore = math.min(60, uniqueLangs * 12);
    final frameworkScore = math.min(40, uniqueFrameworksCount * 8);
    final breadthScore = languageScore + frameworkScore;

    // STEP 5: Activity score
    final activityScore = math.min(100, totalCommits ~/ 10);

    // STEP 6: Total score (0–1000)
    final totalScore = ((depthScore * 0.30 +
                consistencyScore * 0.30 +
                breadthScore * 0.20 +
                activityScore * 0.20) *
            10)
        .round();

    // STEP 7: Rank
    String rank;
    String rankEmoji;
    String rankColor;
    if (totalScore >= 950) {
      rank = 'Elite';
      rankEmoji = '👑';
      rankColor = '#FFD700';
    } else if (totalScore >= 800) {
      rank = 'Pro Dev';
      rankEmoji = '💜';
      rankColor = '#9C27B0';
    } else if (totalScore >= 600) {
      rank = 'Hacker';
      rankEmoji = '🔥';
      rankColor = '#FF5722';
    } else if (totalScore >= 400) {
      rank = 'Builder';
      rankEmoji = '⚡';
      rankColor = '#FFC107';
    } else if (totalScore >= 200) {
      rank = 'Learner';
      rankEmoji = '🔵';
      rankColor = '#2196F3';
    } else {
      rank = 'Beginner';
      rankEmoji = '🌱';
      rankColor = '#9E9E9E';
    }

    // STEP 8: Reasons — handle every edge case
    final activeDayCount = activeDays;

    String depthReason;
    if (topProject == null) {
      depthReason = 'No repositories found on your GitHub profile yet';
    } else if (totalScoredRepos == 1) {
      depthReason =
          '${topProject.projectName} is your only project — '
          '${topProject.commitCount} commits, '
          'scored ${topProject.finalScore.toStringAsFixed(1)} pts';
    } else if (totalScoredRepos < 5) {
      depthReason =
          'Based on your $totalScoredRepos projects — '
          '${topProject.projectName} (${topProject.commitCount} commits) '
          'is your strongest';
    } else {
      depthReason =
          '${topProject.projectName} (${topProject.commitCount} commits) '
          'is your strongest across $totalScoredRepos projects';
    }

    String consistencyReason;
    if (activeDayCount == 0) {
      consistencyReason = 'No commits found in the last 365 days';
    } else if (activeDayCount < 30) {
      consistencyReason =
          'You coded on $activeDayCount days in the last year — '
          'still early, keep going';
    } else {
      consistencyReason =
          'You coded on $activeDayCount of the last 365 days';
    }

    String breadthReason;
    if (uniqueLangs == 0 && uniqueFrameworksCount == 0) {
      breadthReason =
          'No languages or frameworks detected in your repositories yet';
    } else if (uniqueFrameworksCount == 0) {
      breadthReason =
          'Using $uniqueLangs language(s) — no frameworks detected yet';
    } else {
      breadthReason =
          'Using $uniqueLangs language(s) and $uniqueFrameworksCount '
          'framework(s) across all repositories';
    }

    String activityReason;
    if (totalCommits == 0) {
      activityReason = 'No commits made in the last year';
    } else if (totalCommits < 50) {
      activityReason =
          '$totalCommits commits in the last year — just getting started';
    } else {
      activityReason = '$totalCommits commits in the last year';
    }

    // STEP 9: Tips — contextual and specific
    String depthTip;
    if (topProject == null) {
      depthTip =
          'Create your first repository and make at least a few commits '
          'to start scoring';
    } else if (totalScoredRepos == 1) {
      if (topProject.commitCount < 10) {
        depthTip =
            'Keep committing to ${topProject.projectName} — '
            '10+ commits will significantly boost your depth score';
      } else if (topProject.readmeLength < 100) {
        depthTip =
            'Add a README to ${topProject.projectName} '
            'to unlock up to 25 extra depth points';
      } else if (topProject.repoFrameworkCount == 0) {
        depthTip =
            'Add a framework like React, Flutter, or Express to '
            '${topProject.projectName} for extra tech complexity points';
      } else {
        depthTip = 'Start a second project to improve your depth average';
      }
    } else {
      final noReadme =
          allProjectScores.where((p) => p.readmeLength < 100).toList();
      if (noReadme.isNotEmpty) {
        depthTip =
            'Add a README to ${noReadme.first.projectName} '
            'to boost its depth score and raise your average';
      } else if (topProject.commitCount < 30) {
        depthTip =
            'Keep committing to ${topProject.projectName} — '
            '30+ commits unlocks full commit score';
      } else {
        depthTip =
            'Add more frameworks to your next project '
            'to increase tech complexity points';
      }
    }

    String consistencyTip;
    if (activeDayCount == 0) {
      consistencyTip =
          'Start committing regularly — even 1 commit a day adds up fast';
    } else if (activeDayCount < 50) {
      consistencyTip =
          'Aim for 50 active days to reach a meaningful consistency score';
    } else if (activeDaysPercentage < 0.5) {
      final target =
          math.max(1, (heatmapData.length * 0.5).round() - activeDayCount);
      consistencyTip =
          'Code $target more active days to reach 50% consistency';
    } else if (activeDaysPercentage < 0.8) {
      consistencyTip =
          'You are at ${(activeDaysPercentage * 100).round()}% — '
          'aim for 80% to push toward Pro Dev rank';
    } else {
      consistencyTip = 'Excellent consistency — you are in the top tier';
    }

    String breadthTip;
    if (uniqueLangs == 0) {
      breadthTip =
          'Push your first project to start building your breadth score';
    } else if (uniqueFrameworksCount == 0) {
      breadthTip =
          'Add a framework like React, Flutter, Django, or Express '
          'to your next project to start earning framework points';
    } else if (uniqueFrameworksCount < 3) {
      breadthTip =
          'Learn one new framework in your next project '
          'to increase your breadth score';
    } else if (uniqueLangs < 4) {
      breadthTip =
          'Try building a project in a different language '
          'to improve language diversity';
    } else {
      breadthTip = 'Strong tech diversity — you are well-rounded';
    }

    String activityTip;
    if (totalCommits == 0) {
      activityTip = 'Make your first commit to start earning activity score';
    } else if (totalCommits < 100) {
      activityTip =
          '${100 - totalCommits} more commits needed to reach 10 / 100';
    } else if (totalCommits < 500) {
      activityTip = '${500 - totalCommits} more commits to reach 50 / 100';
    } else if (totalCommits < 1000) {
      activityTip =
          '${1000 - totalCommits} more commits to max out activity';
    } else {
      activityTip = 'Activity score maxed out';
    }

    // STEP 10: Build breakdown object
    final scoreBreakdown = DevScoreBreakdown(
      depth: depthScore,
      consistency: consistencyScore,
      breadth: breadthScore,
      activity: activityScore,
      total: totalScore,
      rank: rank,
      rankEmoji: rankEmoji,
      rankColor: rankColor,
      depthReason: depthReason,
      consistencyReason: consistencyReason,
      breadthReason: breadthReason,
      activityReason: activityReason,
      depthTip: depthTip,
      consistencyTip: consistencyTip,
      breadthTip: breadthTip,
      activityTip: activityTip,
      topProjectName: topProject?.projectName ?? '',
      topProjectScore: topProject?.finalScore.round() ?? 0,
    );

    // ── Personality Tags ──────────────────────────────────────
    final ownRepoCount = repos
        .where((r) => (r as Map<String, dynamic>)['isFork'] != true)
        .length;
    final allTopics = projectsList.expand((p) => p.topics).toList();
    final recentPushCount = repos.where((r) {
      final pushed = DateTime.tryParse(
          (r as Map<String, dynamic>)['pushedAt'] as String? ?? '');
      return pushed != null &&
          DateTime.now().difference(pushed).inDays <= 30;
    }).length;
    final collabRepoCount =
        projectsList.where((p) => p.contributorCount > 1 && !p.isFork).length;
    final accountAgeDays =
        DateTime.now().difference(accountCreatedAt).inDays;

    final tags = <String>[];
    void tryAdd(bool condition, String tag) {
      if (tags.length < 3 && condition) tags.add(tag);
    }

    tryAdd(currentStreak >= 14, 'Streak Warrior');
    tryAdd(totalStars >= 50, 'Star Magnet');
    tryAdd(ownRepoCount >= 10, 'Project Builder');
    tryAdd(uniqueLangs >= 5, 'Polyglot Dev');
    tryAdd(totalPRs >= 10, 'Open Source Learner');
    tryAdd(allTopics.any((t) => t.toLowerCase().contains('hackathon')),
        'Hackathon Hunter');
    tryAdd(recentPushCount >= 4, 'Consistent Shipper');
    tryAdd(repos.length >= 15, 'Side Project Addict');
    tryAdd(projectsList.any((p) => p.commitCount >= 50), 'Deep Diver');
    tryAdd(accountAgeDays < 365 && totalScore >= 400, 'Rising Star');
    tryAdd(collabRepoCount >= 3, 'Team Player');

    return DevCardModel(
      userId: userId,
      githubUsername: username,
      githubAvatarUrl: avatarUrl,
      totalPublicRepos: totalRepos,
      totalStars: totalStars,
      totalCommitsLastYear: totalCommits,
      totalPRs: totalPRs,
      totalIssues: totalIssues,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      activeDaysPercentage: activeDaysPercentage,
      topLanguages: topLanguages,
      topFrameworks: topFrameworks,
      personalityTags: tags,
      heatmapData: heatmapData,
      projects: projectsList,
      recentCommits: recentCommits,
      projectScores: allProjectScores,
      scoreBreakdown: scoreBreakdown,
      lastFetchedAt: DateTime.now(),
    );
  }

  // ── Framework detection — reused per-repo and globally ────────────────────
  static Map<String, String> _detectFrameworks(Map<String, dynamic> r) {
    final detected = <String, String>{};

    // package.json
    final pkgText =
        (r['object_package'] as Map<String, dynamic>?)?['text'] as String?;
    if (pkgText != null) {
      try {
        final pkg = jsonDecode(pkgText) as Map<String, dynamic>;
        final allDeps = <String, dynamic>{};
        if (pkg['dependencies'] is Map) {
          allDeps.addAll(pkg['dependencies'] as Map<String, dynamic>);
        }
        if (pkg['devDependencies'] is Map) {
          allDeps.addAll(pkg['devDependencies'] as Map<String, dynamic>);
        }
        const jsMap = {
          'react': ['React', 'web'],
          'next': ['Next.js', 'web'],
          'vue': ['Vue', 'web'],
          '@angular/core': ['Angular', 'web'],
          'express': ['Express', 'backend'],
          '@nestjs/core': ['NestJS', 'backend'],
          'electron': ['Electron', 'desktop'],
          'svelte': ['Svelte', 'web'],
          'nuxt': ['Nuxt', 'web'],
          'socket.io': ['Socket.io', 'backend'],
          'tailwindcss': ['TailwindCSS', 'web'],
          'prisma': ['Prisma', 'backend'],
          'mongoose': ['MongoDB', 'backend'],
          'three': ['Three.js', 'web'],
          'react-native': ['React Native', 'mobile'],
          '@supabase/supabase-js': ['Supabase', 'backend'],
          'firebase': ['Firebase', 'backend'],
        };
        for (final key in allDeps.keys) {
          for (final entry in jsMap.entries) {
            if (key == entry.key || key.startsWith('${entry.key}/')) {
              detected[entry.value[0]] = entry.value[1];
            }
          }
        }
      } catch (_) {}
    }

    // pubspec.yaml
    final pubText =
        (r['object_pubspec'] as Map<String, dynamic>?)?['text'] as String?;
    if (pubText != null) {
      final lower = pubText.toLowerCase();
      const dartMap = {
        'flutter:': ['Flutter', 'mobile'],
        'supabase': ['Supabase', 'backend'],
        'firebase': ['Firebase', 'backend'],
        'riverpod': ['Riverpod', 'mobile'],
        'bloc': ['BLoC', 'mobile'],
        'dio': ['Dio', 'mobile'],
        'hive': ['Hive', 'mobile'],
        'get:': ['GetX', 'mobile'],
      };
      for (final entry in dartMap.entries) {
        if (lower.contains(entry.key)) {
          detected[entry.value[0]] = entry.value[1];
        }
      }
    }

    // requirements.txt
    final reqText =
        (r['object_requirements'] as Map<String, dynamic>?)?['text'] as String?;
    if (reqText != null) {
      final lower = reqText.toLowerCase();
      const pyMap = {
        'django': ['Django', 'web'],
        'flask': ['Flask', 'web'],
        'fastapi': ['FastAPI', 'backend'],
        'tensorflow': ['TensorFlow', 'ml'],
        'torch': ['PyTorch', 'ml'],
        'pandas': ['Pandas', 'ml'],
        'numpy': ['NumPy', 'ml'],
        'scikit': ['Scikit-learn', 'ml'],
        'scrapy': ['Scrapy', 'backend'],
        'celery': ['Celery', 'backend'],
      };
      for (final entry in pyMap.entries) {
        if (lower.contains(entry.key)) {
          detected[entry.value[0]] = entry.value[1];
        }
      }
    }

    // Cargo.toml
    final cargoText =
        (r['object_cargo'] as Map<String, dynamic>?)?['text'] as String?;
    if (cargoText != null) {
      final lower = cargoText.toLowerCase();
      for (final kv in {
        'actix-web': ['Actix', 'backend'],
        'tokio': ['Tokio', 'backend'],
        'rocket': ['Rocket', 'backend'],
      }.entries) {
        if (lower.contains(kv.key)) detected[kv.value[0]] = kv.value[1];
      }
    }

    // go.mod
    final goText =
        (r['object_gomod'] as Map<String, dynamic>?)?['text'] as String?;
    if (goText != null) {
      final lower = goText.toLowerCase();
      for (final kv in {
        'gin-gonic': ['Gin', 'backend'],
        'fiber': ['Fiber', 'backend'],
        'echo': ['Echo', 'backend'],
      }.entries) {
        if (lower.contains(kv.key)) detected[kv.value[0]] = kv.value[1];
      }
    }

    return detected;
  }
}

class _LangAccum {
  final String name;
  final String color;
  int bytes;
  _LangAccum(this.name, this.color) : bytes = 0;
}

class _FwAccum {
  final String name;
  final String category;
  int count;
  _FwAccum(this.name, this.category) : count = 0;
}
