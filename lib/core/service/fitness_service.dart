import 'dart:async';
import 'dart:math';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fitness_flutter/data/fitness_data.dart';
import 'package:fitness_flutter/core/service/gamification_service.dart';

class FitnessService {
  static late Stream<StepCount> _stepCountStream;
  static late Stream<PedestrianStatus> _pedestrianStatusStream;
  static StepCount? _lastStepCount;
  static bool _isTracking = false;
  
  static const String _stepsKey = 'daily_steps';
  static const String _goalsKey = 'fitness_goals';
  static const String _historyKey = 'step_history';
  static const String _userWeightKey = 'user_weight';
  static const String _userHeightKey = 'user_height';

  /// Initialize fitness tracking
  static Future<bool> initialize() async {
    try {
      // Request permissions
      await _requestPermissions();
      
      // Initialize gamification service
      await GamificationService.initialize();
      
      // Start step tracking
      await startStepTracking();
      
      return true;
    } catch (e) {
      print('Error initializing fitness service: $e');
      return false;
    }
  }

  /// Request necessary permissions
  static Future<void> _requestPermissions() async {
    await Permission.activityRecognition.request();
    await Permission.sensors.request();
    
    if (await Permission.activityRecognition.isDenied) {
      throw Exception('Activity recognition permission denied');
    }
  }

  /// Start step tracking
  static Future<void> startStepTracking() async {
    if (_isTracking) return;

    try {
      _stepCountStream = Pedometer.stepCountStream;
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

      _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
      _pedestrianStatusStream.listen(_onPedestrianStatusChanged).onError(_onPedestrianStatusError);
      
      _isTracking = true;
    } catch (e) {
      print('Error starting step tracking: $e');
    }
  }

  /// Handle step count updates
  static void _onStepCount(StepCount event) async {
    print('Step count: ${event.steps}');
    _lastStepCount = event;
    
    // Calculate daily steps (steps since midnight)
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    if (event.timeStamp.isAfter(startOfDay)) {
      await _saveDailySteps(event.steps);
    }
  }

  /// Handle pedestrian status changes
  static void _onPedestrianStatusChanged(PedestrianStatus event) {
    print('Pedestrian status: ${event.status}');
  }

  /// Handle step count errors
  static void _onStepCountError(error) {
    print('Step count error: $error');
  }

  /// Handle pedestrian status errors
  static void _onPedestrianStatusError(error) {
    print('Pedestrian status error: $error');
  }

  /// Save daily steps to local storage
  static Future<void> _saveDailySteps(int totalSteps) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Get previous day's total to calculate today's steps
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final yesterdayKey = '${_stepsKey}_${yesterday.toIso8601String().split('T')[0]}';
    final yesterdayTotal = prefs.getInt(yesterdayKey) ?? 0;
    
    final todaySteps = totalSteps - yesterdayTotal;
    final todayKey = '${_stepsKey}_$today';
    
    await prefs.setInt(todayKey, max(0, todaySteps));
    
    // Calculate calories and distance
    final stepData = await _calculateStepData(max(0, todaySteps));
    await _saveStepData(stepData);
  }

  /// Calculate calories and distance from steps
  static Future<StepData> _calculateStepData(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final weight = prefs.getDouble(_userWeightKey) ?? 70.0; // Default 70kg
    
    // Calories calculation: steps * weight(kg) * 0.04
    final calories = steps * weight * 0.04;
    
    // Distance calculation: steps * average stride length (0.7m)
    final distance = steps * 0.0007; // in kilometers
    
    return StepData(
      date: DateTime.now(),
      steps: steps,
      calories: calories,
      distance: distance,
    );
  }

  /// Save step data to history
  static Future<void> _saveStepData(StepData stepData) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getStepHistory();
    
    // Get previous step data for today to calculate the difference
    StepData? previousTodayData;
    try {
      previousTodayData = history.firstWhere((data) => 
          data.date.year == stepData.date.year &&
          data.date.month == stepData.date.month &&
          data.date.day == stepData.date.day);
    } catch (e) {
      // No previous data for today
    }
    
    // Remove today's data if it exists and add new data
    history.removeWhere((data) => 
        data.date.year == stepData.date.year &&
        data.date.month == stepData.date.month &&
        data.date.day == stepData.date.day);
    
    history.add(stepData);
    
    // Keep only last 30 days
    if (history.length > 30) {
      history.sort((a, b) => b.date.compareTo(a.date));
      history.removeRange(30, history.length);
    }
    
    final historyJson = history.map((data) => data.toJson()).toList();
    await prefs.setString(_historyKey, historyJson.toString());
    
    // Award gamification points for new steps and calories
    if (previousTodayData != null) {
      final newSteps = stepData.steps - previousTodayData.steps;
      final newCalories = stepData.calories - previousTodayData.calories;
      
      if (newSteps > 0) {
        await GamificationService.awardPointsForSteps(newSteps);
      }
      if (newCalories > 0) {
        await GamificationService.awardPointsForCalories(newCalories);
      }
    } else {
      // First time today - award points for all steps and calories
      await GamificationService.awardPointsForSteps(stepData.steps);
      await GamificationService.awardPointsForCalories(stepData.calories);
    }
  }

  /// Get today's steps
  static Future<int> getTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayKey = '${_stepsKey}_$today';
    return prefs.getInt(todayKey) ?? 0;
  }

  /// Get step history
  static Future<List<StepData>> getStepHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey);
    
    if (historyString == null) return [];
    
    try {
      // This is a simplified version - in a real app, you'd use proper JSON parsing
      return []; // Placeholder - implement proper JSON parsing
    } catch (e) {
      return [];
    }
  }

  /// Get fitness goals
  static Future<FitnessGoals> getFitnessGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsString = prefs.getString(_goalsKey);
    
    if (goalsString == null) {
      return FitnessGoals(); // Return default goals
    }
    
    try {
      // This is a simplified version - implement proper JSON parsing
      return FitnessGoals(); // Placeholder
    } catch (e) {
      return FitnessGoals();
    }
  }

  /// Save fitness goals
  static Future<void> saveFitnessGoals(FitnessGoals goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalsKey, goals.toJson().toString());
  }

  /// Save user physical data
  static Future<void> saveUserPhysicalData({double? weight, double? height}) async {
    final prefs = await SharedPreferences.getInstance();
    if (weight != null) await prefs.setDouble(_userWeightKey, weight);
    if (height != null) await prefs.setDouble(_userHeightKey, height);
  }

  /// Get user physical data
  static Future<Map<String, double?>> getUserPhysicalData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'weight': prefs.getDouble(_userWeightKey),
      'height': prefs.getDouble(_userHeightKey),
    };
  }

  /// Calculate BMI
  static double? calculateBMI(double? weight, double? height) {
    if (weight == null || height == null || height <= 0) return null;
    return weight / ((height / 100) * (height / 100));
  }

  /// Get weekly average steps
  static Future<double> getWeeklyAverageSteps() async {
    final history = await getStepHistory();
    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    
    final weeklyData = history.where((data) => data.date.isAfter(weekAgo)).toList();
    
    if (weeklyData.isEmpty) return 0.0;
    
    final totalSteps = weeklyData.map((data) => data.steps).reduce((a, b) => a + b);
    return totalSteps / weeklyData.length;
  }

  /// Set fitness goals
  static Future<void> setFitnessGoals(FitnessGoals goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalsKey, goals.toJson().toString());
  }

  /// Set user weight
  static Future<void> setUserWeight(double weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_userWeightKey, weight);
  }

  /// Set user height  
  static Future<void> setUserHeight(double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_userHeightKey, height);
  }

  /// Check if daily goal is achieved
  static Future<bool> isDailyGoalAchieved() async {
    final todaySteps = await getTodaySteps();
    final goals = await getFitnessGoals();
    return todaySteps >= goals.dailyStepsGoal;
  }

  /// Get progress percentage for today
  static Future<double> getTodayProgress() async {
    final todaySteps = await getTodaySteps();
    final goals = await getFitnessGoals();
    return (todaySteps / goals.dailyStepsGoal).clamp(0.0, 1.0);
  }

  /// Stop step tracking
  static void stopStepTracking() {
    _isTracking = false;
    // Note: You can't actually stop the streams, but you can ignore the events
  }
}
