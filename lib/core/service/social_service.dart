import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_flutter/core/service/fitness_service.dart';
import 'package:fitness_flutter/core/service/gamification_service.dart';

class SocialService {
  static const String _prefsKey = 'social_data';
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _userId;
  
  static SocialData? _currentData;

  static Future<void> initialize() async {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_prefsKey);
    
    if (dataString != null) {
      final Map<String, dynamic> dataMap = jsonDecode(dataString);
      _currentData = SocialData.fromJson(dataMap);
    } else {
      _currentData = SocialData();
      await _saveData();
    }
    
    if (_userId != null) {
      await _syncWithFirestore();
    }
  }

  static Future<void> _saveData() async {
    if (_currentData == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final dataString = jsonEncode(_currentData!.toJson());
    await prefs.setString(_prefsKey, dataString);
  }

  static Future<void> _syncWithFirestore() async {
    if (_userId == null) return;
    
    try {
      // Sync user profile
      await _firestore.collection('users').doc(_userId).set({
        'displayName': _currentData?.userProfile.displayName ?? 'Anonymous',
        'avatarUrl': _currentData?.userProfile.avatarUrl ?? '',
        'totalSteps': await FitnessService.getTodaySteps(),
        'level': GamificationService.currentData.level,
        'points': GamificationService.currentData.totalPoints,
        'lastActive': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing with Firestore: $e');
    }
  }

  static SocialData get currentData => _currentData ?? SocialData();

  /// Create or join a step group
  static Future<bool> createStepGroup({
    required String groupName,
    required String description,
    int maxMembers = 50,
    bool isPrivate = false,
  }) async {
    if (_userId == null) return false;
    
    try {
      final groupRef = _firestore.collection('stepGroups').doc();
      final groupId = groupRef.id;
      
      await groupRef.set({
        'id': groupId,
        'name': groupName,
        'description': description,
        'createdBy': _userId,
        'createdAt': DateTime.now().toIso8601String(),
        'maxMembers': maxMembers,
        'isPrivate': isPrivate,
        'memberCount': 1,
        'totalSteps': 0,
        'weeklyGoal': 70000, // 10,000 steps per day for 7 days
      });
      
      // Add creator as first member
      await _firestore
          .collection('stepGroups')
          .doc(groupId)
          .collection('members')
          .doc(_userId)
          .set({
        'userId': _userId,
        'joinedAt': DateTime.now().toIso8601String(),
        'role': 'admin',
        'weeklySteps': 0,
      });
      
      // Update local data
      _currentData!.joinedGroups.add(groupId);
      await _saveData();
      
      return true;
    } catch (e) {
      print('Error creating step group: $e');
      return false;
    }
  }

  /// Join an existing step group
  static Future<bool> joinStepGroup(String groupId) async {
    if (_userId == null) return false;
    
    try {
      final groupDoc = await _firestore.collection('stepGroups').doc(groupId).get();
      if (!groupDoc.exists) return false;
      
      final groupData = groupDoc.data()!;
      if (groupData['memberCount'] >= groupData['maxMembers']) return false;
      
      // Add user as member
      await _firestore
          .collection('stepGroups')
          .doc(groupId)
          .collection('members')
          .doc(_userId)
          .set({
        'userId': _userId,
        'joinedAt': DateTime.now().toIso8601String(),
        'role': 'member',
        'weeklySteps': 0,
      });
      
      // Update group member count
      await _firestore.collection('stepGroups').doc(groupId).update({
        'memberCount': FieldValue.increment(1),
      });
      
      // Update local data
      _currentData!.joinedGroups.add(groupId);
      await _saveData();
      
      return true;
    } catch (e) {
      print('Error joining step group: $e');
      return false;
    }
  }

  /// Get user's step groups
  static Future<List<Map<String, dynamic>>> getUserStepGroups() async {
    if (_userId == null) return [];
    
    try {
      final groups = <Map<String, dynamic>>[];
      
      for (String groupId in _currentData!.joinedGroups) {
        final groupDoc = await _firestore.collection('stepGroups').doc(groupId).get();
        if (groupDoc.exists) {
          final groupData = groupDoc.data()!;
          
          // Get member data
          final memberDoc = await _firestore
              .collection('stepGroups')
              .doc(groupId)
              .collection('members')
              .doc(_userId)
              .get();
          
          groups.add({
            ...groupData,
            'userRole': memberDoc.data()?['role'] ?? 'member',
            'userWeeklySteps': memberDoc.data()?['weeklySteps'] ?? 0,
          });
        }
      }
      
      return groups;
    } catch (e) {
      print('Error getting user step groups: $e');
      return [];
    }
  }

  /// Get group leaderboard
  static Future<List<Map<String, dynamic>>> getGroupLeaderboard(String groupId) async {
    try {
      final membersQuery = await _firestore
          .collection('stepGroups')
          .doc(groupId)
          .collection('members')
          .orderBy('weeklySteps', descending: true)
          .limit(20)
          .get();
      
      List<Map<String, dynamic>> leaderboard = [];
      
      for (var memberDoc in membersQuery.docs) {
        final memberData = memberDoc.data();
        
        // Get user profile
        final userDoc = await _firestore.collection('users').doc(memberData['userId']).get();
        final userData = userDoc.data() ?? {};
        
        leaderboard.add({
          'userId': memberData['userId'],
          'displayName': userData['displayName'] ?? 'Anonymous',
          'avatarUrl': userData['avatarUrl'] ?? '',
          'weeklySteps': memberData['weeklySteps'] ?? 0,
          'level': userData['level'] ?? 1,
          'points': userData['points'] ?? 0,
          'isCurrentUser': memberData['userId'] == _userId,
        });
      }
      
      return leaderboard;
    } catch (e) {
      print('Error getting group leaderboard: $e');
      return [];
    }
  }

  /// Send encouragement to a friend
  static Future<bool> sendEncouragement(String friendUserId, String message) async {
    if (_userId == null) return false;
    
    try {
      await _firestore.collection('encouragements').add({
        'fromUserId': _userId,
        'toUserId': friendUserId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      });
      
      return true;
    } catch (e) {
      print('Error sending encouragement: $e');
      return false;
    }
  }

  /// Get received encouragements
  static Future<List<Map<String, dynamic>>> getReceivedEncouragements() async {
    if (_userId == null) return [];
    
    try {
      final query = await _firestore
          .collection('encouragements')
          .where('toUserId', isEqualTo: _userId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      
      List<Map<String, dynamic>> encouragements = [];
      
      for (var doc in query.docs) {
        final data = doc.data();
        
        // Get sender profile
        final senderDoc = await _firestore.collection('users').doc(data['fromUserId']).get();
        final senderData = senderDoc.data() ?? {};
        
        encouragements.add({
          'id': doc.id,
          'message': data['message'],
          'timestamp': DateTime.parse(data['timestamp']),
          'isRead': data['isRead'] ?? false,
          'sender': {
            'userId': data['fromUserId'],
            'displayName': senderData['displayName'] ?? 'Anonymous',
            'avatarUrl': senderData['avatarUrl'] ?? '',
          },
        });
      }
      
      return encouragements;
    } catch (e) {
      print('Error getting encouragements: $e');
      return [];
    }
  }

  /// Challenge a friend to step competition
  static Future<bool> challengeFriend({
    required String friendUserId,
    required String challengeType,
    required int duration, // days
    required int target, // steps
  }) async {
    if (_userId == null) return false;
    
    try {
      await _firestore.collection('challenges').add({
        'challengerId': _userId,
        'challengeeId': friendUserId,
        'type': challengeType,
        'target': target,
        'duration': duration,
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(Duration(days: duration)).toIso8601String(),
        'status': 'pending',
        'challengerSteps': 0,
        'challengeeSteps': 0,
      });
      
      return true;
    } catch (e) {
      print('Error creating challenge: $e');
      return false;
    }
  }

  /// Get active challenges
  static Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    if (_userId == null) return [];
    
    try {
      final query = await _firestore
          .collection('challenges')
          .where('challengerId', isEqualTo: _userId)
          .where('status', isEqualTo: 'active')
          .get();
      
      final query2 = await _firestore
          .collection('challenges')
          .where('challengeeId', isEqualTo: _userId)
          .where('status', isEqualTo: 'active')
          .get();
      
      List<Map<String, dynamic>> challenges = [];
      
      for (var doc in [...query.docs, ...query2.docs]) {
        final data = doc.data();
        final isChallenger = data['challengerId'] == _userId;
        final opponentId = isChallenger ? data['challengeeId'] : data['challengerId'];
        
        // Get opponent profile
        final opponentDoc = await _firestore.collection('users').doc(opponentId).get();
        final opponentData = opponentDoc.data() ?? {};
        
        challenges.add({
          'id': doc.id,
          'type': data['type'],
          'target': data['target'],
          'endDate': DateTime.parse(data['endDate']),
          'isChallenger': isChallenger,
          'mySteps': isChallenger ? data['challengerSteps'] : data['challengeeSteps'],
          'opponentSteps': isChallenger ? data['challengeeSteps'] : data['challengerSteps'],
          'opponent': {
            'userId': opponentId,
            'displayName': opponentData['displayName'] ?? 'Anonymous',
            'avatarUrl': opponentData['avatarUrl'] ?? '',
          },
        });
      }
      
      return challenges;
    } catch (e) {
      print('Error getting active challenges: $e');
      return [];
    }
  }

  /// Post to community feed
  static Future<bool> postToCommunityFeed({
    required String content,
    String? imageUrl,
    Map<String, dynamic>? achievement,
  }) async {
    if (_userId == null) return false;
    
    try {
      await _firestore.collection('communityFeed').add({
        'userId': _userId,
        'content': content,
        'imageUrl': imageUrl,
        'achievement': achievement,
        'timestamp': DateTime.now().toIso8601String(),
        'likes': 0,
        'comments': 0,
      });
      
      return true;
    } catch (e) {
      print('Error posting to community feed: $e');
      return false;
    }
  }

  /// Get community feed
  static Future<List<Map<String, dynamic>>> getCommunityFeed({int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('communityFeed')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      List<Map<String, dynamic>> feed = [];
      
      for (var doc in query.docs) {
        final data = doc.data();
        
        // Get user profile
        final userDoc = await _firestore.collection('users').doc(data['userId']).get();
        final userData = userDoc.data() ?? {};
        
        feed.add({
          'id': doc.id,
          'content': data['content'],
          'imageUrl': data['imageUrl'],
          'achievement': data['achievement'],
          'timestamp': DateTime.parse(data['timestamp']),
          'likes': data['likes'] ?? 0,
          'comments': data['comments'] ?? 0,
          'user': {
            'userId': data['userId'],
            'displayName': userData['displayName'] ?? 'Anonymous',
            'avatarUrl': userData['avatarUrl'] ?? '',
            'level': userData['level'] ?? 1,
          },
        });
      }
      
      return feed;
    } catch (e) {
      print('Error getting community feed: $e');
      return [];
    }
  }

  /// Update user profile
  static Future<bool> updateUserProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    if (_userId == null) return false;
    
    try {
      Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      
      await _firestore.collection('users').doc(_userId).update(updates);
      
      // Update local data
      if (displayName != null) {
        _currentData = _currentData!.copyWith(
          userProfile: _currentData!.userProfile.copyWith(displayName: displayName),
        );
      }
      if (avatarUrl != null) {
        _currentData = _currentData!.copyWith(
          userProfile: _currentData!.userProfile.copyWith(avatarUrl: avatarUrl),
        );
      }
      
      await _saveData();
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Search for users
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();
      
      List<Map<String, dynamic>> users = [];
      
      for (var doc in usersQuery.docs) {
        final data = doc.data();
        if (doc.id != _userId) { // Exclude current user
          users.add({
            'userId': doc.id,
            'displayName': data['displayName'] ?? 'Anonymous',
            'avatarUrl': data['avatarUrl'] ?? '',
            'level': data['level'] ?? 1,
            'points': data['points'] ?? 0,
          });
        }
      }
      
      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}

class SocialData {
  final UserProfile userProfile;
  final List<String> friends;
  final List<String> joinedGroups;
  final List<String> pendingInvites;

  SocialData({
    UserProfile? userProfile,
    List<String>? friends,
    List<String>? joinedGroups,
    List<String>? pendingInvites,
  }) : userProfile = userProfile ?? UserProfile(),
        friends = friends ?? [],
        joinedGroups = joinedGroups ?? [],
        pendingInvites = pendingInvites ?? [];

  SocialData copyWith({
    UserProfile? userProfile,
    List<String>? friends,
    List<String>? joinedGroups,
    List<String>? pendingInvites,
  }) {
    return SocialData(
      userProfile: userProfile ?? this.userProfile,
      friends: friends ?? this.friends,
      joinedGroups: joinedGroups ?? this.joinedGroups,
      pendingInvites: pendingInvites ?? this.pendingInvites,
    );
  }

  factory SocialData.fromJson(Map<String, dynamic> json) {
    return SocialData(
      userProfile: UserProfile.fromJson(json['userProfile'] ?? {}),
      friends: List<String>.from(json['friends'] ?? []),
      joinedGroups: List<String>.from(json['joinedGroups'] ?? []),
      pendingInvites: List<String>.from(json['pendingInvites'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userProfile': userProfile.toJson(),
      'friends': friends,
      'joinedGroups': joinedGroups,
      'pendingInvites': pendingInvites,
    };
  }
}

class UserProfile {
  final String displayName;
  final String avatarUrl;
  final String bio;

  const UserProfile({
    this.displayName = 'Anonymous',
    this.avatarUrl = '',
    this.bio = '',
  });

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] ?? 'Anonymous',
      avatarUrl: json['avatarUrl'] ?? '',
      bio: json['bio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
    };
  }
}
