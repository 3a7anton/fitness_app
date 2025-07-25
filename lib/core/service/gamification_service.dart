import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_flutter/data/gamification_data.dart';

class GamificationService {
  static const String _gamificationKey = 'gamification_data';
  static const String _pointsKey = 'total_points';
  static const String _levelKey = 'user_level';
  static const String _leagueKey = 'user_league';
  
  static GamificationData? _currentData;
  static final List<Badge> _allBadges = _initializeBadges();
  static final List<Avatar> _allAvatars = _initializeAvatars();

  // Points System: 100 steps = 0.01 points (1 point = 10,000 steps)
  static const double _pointsPerStep = 0.0001;
  static const double _pointsPerCalorie = 0.1;
  static const int _dailyLoginBonus = 10;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_gamificationKey);
    
    if (dataString != null) {
      final Map<String, dynamic> dataMap = jsonDecode(dataString);
      _currentData = GamificationData.fromJson(dataMap);
    } else {
      _currentData = GamificationData(
        lastDailyReward: DateTime.now().subtract(const Duration(days: 1)),
      );
      await _saveData();
    }
    
    // Initialize daily challenges if needed
    await _initializeDailyChallenges();
  }

  static Future<void> _saveData() async {
    if (_currentData == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final dataString = jsonEncode(_currentData!.toJson());
    await prefs.setString(_gamificationKey, dataString);
  }

  static GamificationData get currentData => _currentData ?? GamificationData(lastDailyReward: DateTime.now());

  // Points System
  static Future<int> addPointsForSteps(int steps) async {
    final points = (steps * _pointsPerStep).round();
    return await addPoints(points);
  }

  static Future<int> addPointsForCalories(double calories) async {
    final points = (calories * _pointsPerCalorie).round();
    return await addPoints(points);
  }

  static Future<int> addPoints(int points) async {
    if (_currentData == null) await initialize();
    
    final newTotal = _currentData!.totalPoints + points;
    final newLeague = League.getLeagueForPoints(newTotal);
    final newLevel = _calculateLevel(newTotal);
    
    _currentData = _currentData!.copyWith(
      totalPoints: newTotal,
      currentLeague: newLeague,
      level: newLevel,
    );
    
    await _saveData();
    await _checkForNewBadges();
    
    return points;
  }

  // Alias methods for fitness service integration
  static Future<int> awardPointsForSteps(int steps) async {
    return await addPointsForSteps(steps);
  }

  static Future<int> awardPointsForCalories(double calories) async {
    return await addPointsForCalories(calories);
  }

  static int _calculateLevel(int totalPoints) {
    // Level formula: level = floor(sqrt(totalPoints / 100)) + 1
    return (sqrt(totalPoints / 100)).floor() + 1;
  }

  static int getPointsForNextLevel(int currentLevel) {
    return ((currentLevel * currentLevel) * 100);
  }

  // Daily Login Bonus
  static Future<int> claimDailyBonus() async {
    if (_currentData == null) await initialize();
    
    final now = DateTime.now();
    final lastReward = _currentData!.lastDailyReward;
    
    if (now.day != lastReward.day || now.month != lastReward.month || now.year != lastReward.year) {
      _currentData = _currentData!.copyWith(lastDailyReward: now);
      await addPoints(_dailyLoginBonus);
      await _saveData();
      return _dailyLoginBonus;
    }
    
    return 0;
  }

  static bool canClaimDailyBonus() {
    if (_currentData == null) return true;
    
    final now = DateTime.now();
    final lastReward = _currentData!.lastDailyReward;
    
    return now.day != lastReward.day || now.month != lastReward.month || now.year != lastReward.year;
  }

  // Badges System
  static List<Badge> getAllBadges() => _allBadges;
  
  static List<Badge> getEarnedBadges() => _currentData?.earnedBadges ?? [];
  
  static Future<void> _checkForNewBadges() async {
    if (_currentData == null) return;
    
    final earnedBadgeIds = _currentData!.earnedBadges.map((b) => b.id).toSet();
    final newBadges = <Badge>[];
    
    for (final badge in _allBadges) {
      if (!earnedBadgeIds.contains(badge.id) && _isBadgeEarned(badge)) {
        final earnedBadge = badge.copyWith(earnedDate: DateTime.now());
        newBadges.add(earnedBadge);
      }
    }
    
    if (newBadges.isNotEmpty) {
      final updatedBadges = List<Badge>.from(_currentData!.earnedBadges)..addAll(newBadges);
      _currentData = _currentData!.copyWith(earnedBadges: updatedBadges);
      
      // Award points for badges
      final badgePoints = newBadges.fold<int>(0, (sum, badge) => sum + badge.pointsReward);
      await addPoints(badgePoints);
      
      await _saveData();
    }
  }

  static bool _isBadgeEarned(Badge badge) {
    final data = _currentData!;
    
    if (badge.type == BadgeType.steps) {
      // This would need to check total steps from fitness service
      return data.totalPoints >= badge.requirement; // Simplified
    } else if (badge.type == BadgeType.calories) {
      return data.totalPoints >= badge.requirement; // Simplified
    } else if (badge.type == BadgeType.days) {
      return data.level >= badge.requirement;
    } else if (badge.type == BadgeType.challenges) {
      return data.completedChallenges.length >= badge.requirement;
    } else if (badge.type == BadgeType.streak) {
      return data.level >= badge.requirement; // Simplified
    }
    
    return false; // Default case
  }

  // Avatar System
  static List<Avatar> getAllAvatars() => _allAvatars;
  
  static Avatar getSelectedAvatar() => _currentData?.selectedAvatar ?? const Avatar();
  
  static Future<bool> unlockAvatar(String avatarId) async {
    if (_currentData == null) await initialize();
    
    final avatar = _allAvatars.firstWhere((a) => a.id == avatarId);
    
    if (_currentData!.totalPoints >= avatar.unlockCost) {
      await addPoints(-avatar.unlockCost); // Deduct points
      return true;
    }
    
    return false;
  }

  static Future<void> selectAvatar(Avatar avatar) async {
    if (_currentData == null) await initialize();
    
    _currentData = _currentData!.copyWith(selectedAvatar: avatar);
    await _saveData();
  }

  // Challenges System
  static List<Challenge> getActiveChallenges() => _currentData?.activeChallenges ?? [];
  
  static List<Challenge> getCompletedChallenges() => _currentData?.completedChallenges ?? [];

  static Future<void> _initializeDailyChallenges() async {
    if (_currentData == null) return;
    
    final now = DateTime.now();
    final hasActiveDailyChallenge = _currentData!.activeChallenges
        .any((c) => c.isDaily && c.startDate.day == now.day);
    
    if (!hasActiveDailyChallenge) {
      final dailyChallenge = _generateDailyChallenge();
      final updatedChallenges = List<Challenge>.from(_currentData!.activeChallenges)
        ..add(dailyChallenge);
      
      _currentData = _currentData!.copyWith(activeChallenges: updatedChallenges);
      await _saveData();
    }
  }

  static Challenge _generateDailyChallenge() {
    final random = Random();
    final challenges = [
      Challenge(
        id: 'daily_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Daily Step Goal',
        description: 'Walk 5,000 steps today',
        type: ChallengeType.steps,
        target: 5000,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        pointsReward: 50,
        isDaily: true,
      ),
      Challenge(
        id: 'daily_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Calorie Burn',
        description: 'Burn 200 calories today',
        type: ChallengeType.calories,
        target: 200,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        pointsReward: 75,
        isDaily: true,
      ),
    ];
    
    return challenges[random.nextInt(challenges.length)];
  }

  static Future<void> updateChallengeProgress(ChallengeType type, int value) async {
    if (_currentData == null) return;
    
    final updatedChallenges = <Challenge>[];
    final completedChallenges = List<Challenge>.from(_currentData!.completedChallenges);
    
    for (final challenge in _currentData!.activeChallenges) {
      if (challenge.type == type && !challenge.isCompleted) {
        final newProgress = challenge.currentProgress + value;
        final isNowCompleted = newProgress >= challenge.target;
        
        final updatedChallenge = challenge.copyWith(
          currentProgress: newProgress,
          isCompleted: isNowCompleted,
        );
        
        if (isNowCompleted) {
          completedChallenges.add(updatedChallenge);
          await addPoints(challenge.pointsReward);
        } else {
          updatedChallenges.add(updatedChallenge);
        }
      } else {
        updatedChallenges.add(challenge);
      }
    }
    
    _currentData = _currentData!.copyWith(
      activeChallenges: updatedChallenges,
      completedChallenges: completedChallenges,
    );
    
    await _saveData();
  }

  static Future<void> addWeeklyChallenge() async {
    final weeklyChallenge = Challenge(
      id: 'weekly_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Weekly Warrior',
      description: 'Complete 35,000 steps this week',
      type: ChallengeType.steps,
      target: 35000,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      pointsReward: 500,
      isDaily: false,
    );
    
    final updatedChallenges = List<Challenge>.from(_currentData!.activeChallenges)
      ..add(weeklyChallenge);
    
    _currentData = _currentData!.copyWith(activeChallenges: updatedChallenges);
    await _saveData();
  }

  // Initialize default badges
  static List<Badge> _initializeBadges() {
    return [
      const Badge(
        id: 'first_steps',
        name: 'First Steps',
        description: 'Take your first 100 steps',
        iconPath: 'assets/icons/badges/first_steps.png',
        type: BadgeType.steps,
        requirement: 100,
        pointsReward: 25,
      ),
      const Badge(
        id: 'step_master',
        name: 'Step Master',
        description: 'Reach 10,000 steps in a day',
        iconPath: 'assets/icons/badges/step_master.png',
        type: BadgeType.steps,
        requirement: 10000,
        pointsReward: 100,
      ),
      const Badge(
        id: 'calorie_crusher',
        name: 'Calorie Crusher',
        description: 'Burn 500 calories in a day',
        iconPath: 'assets/icons/badges/calorie_crusher.png',
        type: BadgeType.calories,
        requirement: 500,
        pointsReward: 75,
      ),
      const Badge(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: 'Stay active for 7 consecutive days',
        iconPath: 'assets/icons/badges/week_warrior.png',
        type: BadgeType.streak,
        requirement: 7,
        pointsReward: 200,
      ),
      const Badge(
        id: 'challenge_champion',
        name: 'Challenge Champion',
        description: 'Complete 10 challenges',
        iconPath: 'assets/icons/badges/challenge_champion.png',
        type: BadgeType.challenges,
        requirement: 10,
        pointsReward: 300,
      ),
    ];
  }

  // Initialize default avatars
  static List<Avatar> _initializeAvatars() {
    return [
      const Avatar(
        id: 'default',
        name: 'Classic Runner',
        imagePath: 'assets/images/avatars/classic.png',
        skin: AvatarSkin.classic,
        isUnlocked: true,
        unlockCost: 0,
      ),
      const Avatar(
        id: 'sporty',
        name: 'Sporty Athlete',
        imagePath: 'assets/images/avatars/sporty.png',
        skin: AvatarSkin.sporty,
        isUnlocked: false,
        unlockCost: 100,
      ),
      const Avatar(
        id: 'ninja',
        name: 'Shadow Ninja',
        imagePath: 'assets/images/avatars/ninja.png',
        skin: AvatarSkin.ninja,
        isUnlocked: false,
        unlockCost: 250,
      ),
      const Avatar(
        id: 'robot',
        name: 'Cyber Runner',
        imagePath: 'assets/images/avatars/robot.png',
        skin: AvatarSkin.robot,
        isUnlocked: false,
        unlockCost: 500,
      ),
      const Avatar(
        id: 'superhero',
        name: 'Super Hero',
        imagePath: 'assets/images/avatars/superhero.png',
        skin: AvatarSkin.superhero,
        isUnlocked: false,
        unlockCost: 750,
      ),
      const Avatar(
        id: 'golden',
        name: 'Golden Legend',
        imagePath: 'assets/images/avatars/golden.png',
        skin: AvatarSkin.golden,
        isUnlocked: false,
        unlockCost: 1000,
      ),
    ];
  }

  // Stats and Analytics
  static Map<String, dynamic> getGamificationStats() {
    final data = currentData;
    return {
      'totalPoints': data.totalPoints,
      'currentLeague': data.currentLeague.name,
      'level': data.level,
      'pointsToNextLevel': getPointsForNextLevel(data.level) - data.totalPoints,
      'earnedBadges': data.earnedBadges.length,
      'totalBadges': _allBadges.length,
      'completedChallenges': data.completedChallenges.length,
      'activeChallenges': data.activeChallenges.length,
      'selectedAvatar': data.selectedAvatar.name,
    };
  }

  /// Get user stats for cloud sync
  static Future<Map<String, dynamic>> getUserStats() async {
    if (_currentData == null) await initialize();
    return getGamificationStats();
  }

  /// Get unlocked badges for cloud sync
  static Future<List<Map<String, dynamic>>> getUnlockedBadges() async {
    if (_currentData == null) await initialize();
    return _currentData!.earnedBadges.map((badge) => {
      'id': badge.id,
      'name': badge.name,
      'description': badge.description,
      'iconPath': badge.iconPath,
      'earnedDate': badge.earnedDate?.toIso8601String(),
    }).toList();
  }
}
