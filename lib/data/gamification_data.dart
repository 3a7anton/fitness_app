class GamificationData {
  final int totalPoints;
  final League currentLeague;
  final int level;
  final Avatar selectedAvatar;
  final List<Badge> earnedBadges;
  final List<Challenge> activeChallenges;
  final List<Challenge> completedChallenges;
  final DateTime lastDailyReward;

  const GamificationData({
    this.totalPoints = 0,
    this.currentLeague = League.bronze,
    this.level = 1,
    this.selectedAvatar = const Avatar(),
    this.earnedBadges = const [],
    this.activeChallenges = const [],
    this.completedChallenges = const [],
    required this.lastDailyReward,
  });

  GamificationData copyWith({
    int? totalPoints,
    League? currentLeague,
    int? level,
    Avatar? selectedAvatar,
    List<Badge>? earnedBadges,
    List<Challenge>? activeChallenges,
    List<Challenge>? completedChallenges,
    DateTime? lastDailyReward,
  }) {
    return GamificationData(
      totalPoints: totalPoints ?? this.totalPoints,
      currentLeague: currentLeague ?? this.currentLeague,
      level: level ?? this.level,
      selectedAvatar: selectedAvatar ?? this.selectedAvatar,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      activeChallenges: activeChallenges ?? this.activeChallenges,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      lastDailyReward: lastDailyReward ?? this.lastDailyReward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'currentLeague': currentLeague.name,
      'level': level,
      'selectedAvatar': selectedAvatar.toJson(),
      'earnedBadges': earnedBadges.map((badge) => badge.toJson()).toList(),
      'activeChallenges': activeChallenges.map((challenge) => challenge.toJson()).toList(),
      'completedChallenges': completedChallenges.map((challenge) => challenge.toJson()).toList(),
      'lastDailyReward': lastDailyReward.toIso8601String(),
    };
  }

  factory GamificationData.fromJson(Map<String, dynamic> json) {
    return GamificationData(
      totalPoints: json['totalPoints'] ?? 0,
      currentLeague: League.values.firstWhere(
        (league) => league.name == json['currentLeague'],
        orElse: () => League.bronze,
      ),
      level: json['level'] ?? 1,
      selectedAvatar: json['selectedAvatar'] != null 
          ? Avatar.fromJson(json['selectedAvatar']) 
          : const Avatar(),
      earnedBadges: json['earnedBadges'] != null
          ? List<Badge>.from(json['earnedBadges'].map((badge) => Badge.fromJson(badge)))
          : [],
      activeChallenges: json['activeChallenges'] != null
          ? List<Challenge>.from(json['activeChallenges'].map((challenge) => Challenge.fromJson(challenge)))
          : [],
      completedChallenges: json['completedChallenges'] != null
          ? List<Challenge>.from(json['completedChallenges'].map((challenge) => Challenge.fromJson(challenge)))
          : [],
      lastDailyReward: json['lastDailyReward'] != null
          ? DateTime.parse(json['lastDailyReward'])
          : DateTime.now().subtract(const Duration(days: 1)),
    );
  }
}

class League {
  static const bronze = League('Bronze', 0, 1000, '🥉');
  static const silver = League('Silver', 1000, 5000, '🥈');
  static const gold = League('Gold', 5000, 15000, '🥇');
  static const diamond = League('Diamond', 15000, double.infinity, '💎');

  static const List<League> values = [bronze, silver, gold, diamond];

  const League(this.name, this.minPoints, this.maxPoints, this.icon);
  
  final String name;
  final double minPoints;
  final double maxPoints;
  final String icon;

  static League getLeagueForPoints(int points) {
    for (League league in values.reversed) {
      if (points >= league.minPoints) {
        return league;
      }
    }
    return bronze;
  }

  double getProgressToNextLeague(int points) {
    if (this == diamond) return 1.0;
    final progress = (points - minPoints) / (maxPoints - minPoints);
    return progress.clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is League &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class Avatar {
  final String id;
  final String name;
  final String imagePath;
  final AvatarSkin skin;
  final bool isUnlocked;
  final int unlockCost;

  const Avatar({
    this.id = 'default',
    this.name = 'Default Runner',
    this.imagePath = 'assets/images/avatars/default.png',
    this.skin = AvatarSkin.classic,
    this.isUnlocked = true,
    this.unlockCost = 0,
  });

  Avatar copyWith({
    String? id,
    String? name,
    String? imagePath,
    AvatarSkin? skin,
    bool? isUnlocked,
    int? unlockCost,
  }) {
    return Avatar(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      skin: skin ?? this.skin,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockCost: unlockCost ?? this.unlockCost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'skin': skin.name,
      'isUnlocked': isUnlocked,
      'unlockCost': unlockCost,
    };
  }

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'] ?? 'default',
      name: json['name'] ?? 'Default Runner',
      imagePath: json['imagePath'] ?? 'assets/images/avatars/default.png',
      skin: AvatarSkin.values.firstWhere(
        (skin) => skin.name == json['skin'],
        orElse: () => AvatarSkin.classic,
      ),
      isUnlocked: json['isUnlocked'] ?? true,
      unlockCost: json['unlockCost'] ?? 0,
    );
  }
}

class AvatarSkin {
  static const classic = AvatarSkin('Classic', 'assets/images/avatars/classic.png', 0);
  static const sporty = AvatarSkin('Sporty', 'assets/images/avatars/sporty.png', 100);
  static const ninja = AvatarSkin('Ninja', 'assets/images/avatars/ninja.png', 250);
  static const robot = AvatarSkin('Robot', 'assets/images/avatars/robot.png', 500);
  static const superhero = AvatarSkin('Superhero', 'assets/images/avatars/superhero.png', 750);
  static const golden = AvatarSkin('Golden', 'assets/images/avatars/golden.png', 1000);

  static const List<AvatarSkin> values = [classic, sporty, ninja, robot, superhero, golden];

  const AvatarSkin(this.name, this.imagePath, this.unlockCost);
  
  final String name;
  final String imagePath;
  final int unlockCost;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarSkin &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final BadgeType type;
  final int requirement;
  final DateTime? earnedDate;
  final int pointsReward;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.type,
    required this.requirement,
    this.earnedDate,
    this.pointsReward = 50,
  });

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? iconPath,
    BadgeType? type,
    int? requirement,
    DateTime? earnedDate,
    int? pointsReward,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      type: type ?? this.type,
      requirement: requirement ?? this.requirement,
      earnedDate: earnedDate ?? this.earnedDate,
      pointsReward: pointsReward ?? this.pointsReward,
    );
  }

  bool get isEarned => earnedDate != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'type': type.name,
      'requirement': requirement,
      'earnedDate': earnedDate?.toIso8601String(),
      'pointsReward': pointsReward,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconPath: json['iconPath'],
      type: BadgeType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => BadgeType.steps,
      ),
      requirement: json['requirement'],
      earnedDate: json['earnedDate'] != null 
          ? DateTime.parse(json['earnedDate']) 
          : null,
      pointsReward: json['pointsReward'] ?? 50,
    );
  }
}

class BadgeType {
  static const steps = BadgeType('Steps');
  static const calories = BadgeType('Calories');
  static const days = BadgeType('Days');
  static const challenges = BadgeType('Challenges');
  static const streak = BadgeType('Streak');

  static const List<BadgeType> values = [steps, calories, days, challenges, streak];

  const BadgeType(this.displayName);
  final String displayName;

  String get name => displayName.toLowerCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeType &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName;

  @override
  int get hashCode => displayName.hashCode;
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int target;
  final int currentProgress;
  final DateTime startDate;
  final DateTime endDate;
  final int pointsReward;
  final bool isCompleted;
  final bool isDaily;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.currentProgress = 0,
    required this.startDate,
    required this.endDate,
    this.pointsReward = 100,
    this.isCompleted = false,
    this.isDaily = false,
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    int? target,
    int? currentProgress,
    DateTime? startDate,
    DateTime? endDate,
    int? pointsReward,
    bool? isCompleted,
    bool? isDaily,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      currentProgress: currentProgress ?? this.currentProgress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pointsReward: pointsReward ?? this.pointsReward,
      isCompleted: isCompleted ?? this.isCompleted,
      isDaily: isDaily ?? this.isDaily,
    );
  }

  double get progressPercentage => target > 0 ? (currentProgress / target).clamp(0.0, 1.0) : 0.0;
  
  bool get isExpired => DateTime.now().isAfter(endDate);
  
  Duration get timeRemaining => endDate.difference(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'target': target,
      'currentProgress': currentProgress,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'pointsReward': pointsReward,
      'isCompleted': isCompleted,
      'isDaily': isDaily,
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ChallengeType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => ChallengeType.steps,
      ),
      target: json['target'],
      currentProgress: json['currentProgress'] ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      pointsReward: json['pointsReward'] ?? 100,
      isCompleted: json['isCompleted'] ?? false,
      isDaily: json['isDaily'] ?? false,
    );
  }
}

class ChallengeType {
  static const steps = ChallengeType('Steps Challenge');
  static const calories = ChallengeType('Calories Challenge');
  static const distance = ChallengeType('Distance Challenge');
  static const streak = ChallengeType('Streak Challenge');

  static const List<ChallengeType> values = [steps, calories, distance, streak];

  const ChallengeType(this.displayName);
  final String displayName;

  String get name => displayName.toLowerCase().replaceAll(' challenge', '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeType &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName;

  @override
  int get hashCode => displayName.hashCode;
}
