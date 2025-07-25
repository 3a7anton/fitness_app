import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_flutter/data/fitness_data.dart';
import 'package:fitness_flutter/core/service/fitness_service.dart';
import 'package:fitness_flutter/core/service/gamification_service.dart';

class CloudSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get _userId => _auth.currentUser?.uid;

  /// Sync fitness data to cloud
  static Future<bool> syncFitnessDataToCloud() async {
    if (_userId == null) return false;

    try {
      // Get local fitness data
      final goals = await FitnessService.getFitnessGoals();
      final stepHistory = await FitnessService.getStepHistory();
      final physicalData = await FitnessService.getUserPhysicalData();

      // Upload fitness goals
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('fitness')
          .doc('goals')
          .set(goals.toJson());

      // Upload step history
      for (final stepData in stepHistory) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('fitness')
            .doc('steps')
            .collection('history')
            .doc(stepData.date.toIso8601String().substring(0, 10))
            .set(stepData.toJson());
      }

      // Upload physical data
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('fitness')
          .doc('physical')
          .set({
        'weight': physicalData['weight'],
        'height': physicalData['height'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error syncing fitness data to cloud: $e');
      return false;
    }
  }

  /// Sync gamification data to cloud
  static Future<bool> syncGamificationDataToCloud() async {
    if (_userId == null) return false;

    try {
      final userStats = await GamificationService.getUserStats();
      final badges = await GamificationService.getUnlockedBadges();
      final challenges = await GamificationService.getActiveChallenges();

      // Upload user stats
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('gamification')
          .doc('stats')
          .set({
        'totalPoints': userStats['totalPoints'],
        'currentLeague': userStats['currentLeague'],
        'level': userStats['level'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Upload badges
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('gamification')
          .doc('badges')
          .set({
        'unlockedBadges': badges.map((badge) => badge.toJson()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Upload challenges
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('gamification')
          .doc('challenges')
          .set({
        'activeChallenges': challenges.map((challenge) => challenge.toJson()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error syncing gamification data to cloud: $e');
      return false;
    }
  }

  /// Download fitness data from cloud
  static Future<bool> downloadFitnessDataFromCloud() async {
    if (_userId == null) return false;

    try {
      // Download fitness goals
      final goalsDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('fitness')
          .doc('goals')
          .get();

      if (goalsDoc.exists) {
        final goals = FitnessGoals.fromJson(goalsDoc.data()!);
        await FitnessService.setFitnessGoals(goals);
      }

      // Download physical data
      final physicalDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('fitness')
          .doc('physical')
          .get();

      if (physicalDoc.exists) {
        final data = physicalDoc.data()!;
        if (data['weight'] != null) {
          await FitnessService.setUserWeight(data['weight']);
        }
        if (data['height'] != null) {
          await FitnessService.setUserHeight(data['height']);
        }
      }

      return true;
    } catch (e) {
      print('Error downloading fitness data from cloud: $e');
      return false;
    }
  }

  /// Download gamification data from cloud
  static Future<bool> downloadGamificationDataFromCloud() async {
    if (_userId == null) return false;

    try {
      // Download user stats
      final statsDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('gamification')
          .doc('stats')
          .get();

      if (statsDoc.exists) {
        final data = statsDoc.data()!;
        // Apply cloud stats to local storage
        // This would require additional methods in GamificationService
        print('Downloaded user stats: $data');
      }

      return true;
    } catch (e) {
      print('Error downloading gamification data from cloud: $e');
      return false;
    }
  }

  /// Auto-sync when user signs in
  static Future<void> autoSyncOnSignIn() async {
    if (_userId == null) return;

    // Download data first, then upload any newer local data
    await downloadFitnessDataFromCloud();
    await downloadGamificationDataFromCloud();
    
    // Upload current local data
    await syncFitnessDataToCloud();
    await syncGamificationDataToCloud();
  }

  /// Periodic sync (call this periodically)
  static Future<void> performPeriodicSync() async {
    await syncFitnessDataToCloud();
    await syncGamificationDataToCloud();
  }

  /// Listen to real-time updates
  static Stream<DocumentSnapshot> listenToUserFitnessData() {
    if (_userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('fitness')
        .doc('goals')
        .snapshots();
  }
}
