import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CarbonFootprintService {
  static const String _dataKey = 'carbon_footprint_data';
  static const String _preferencesKey = 'carbon_preferences';
  
  // Carbon emission factors (kg CO₂ per km)
  static const double _carEmissionFactor = 0.251; // Average car
  static const double _busEmissionFactor = 0.089; // Public bus
  static const double _trainEmissionFactor = 0.041; // Electric train
  static const double _walkingEmissionFactor = 0.0; // Walking is carbon neutral
  static const double _cyclingEmissionFactor = 0.021; // Including bike manufacturing
  
  // Conversion factors
  static const double _stepsToKm = 0.0008; // Average: 1250 steps = 1 km
  static const double _averageWalkingSpeed = 5.0; // km/h
  
  static CarbonFootprintData? _currentData;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_dataKey);
    
    if (dataString != null) {
      final Map<String, dynamic> dataMap = jsonDecode(dataString);
      _currentData = CarbonFootprintData.fromJson(dataMap);
    } else {
      _currentData = CarbonFootprintData();
      await _saveData();
    }
  }

  static Future<void> _saveData() async {
    if (_currentData == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final dataString = jsonEncode(_currentData!.toJson());
    await prefs.setString(_dataKey, dataString);
  }

  static CarbonFootprintData get currentData => _currentData ?? CarbonFootprintData();

  /// Calculate carbon saved from walking steps
  static Future<double> calculateCarbonSavedFromSteps(int steps) async {
    if (_currentData == null) await initialize();
    
    final distanceKm = steps * _stepsToKm;
    final carbonSaved = distanceKm * _carEmissionFactor; // Assuming replaced car travel
    
    // Update daily savings
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    final updatedDailySavings = Map<String, double>.from(_currentData!.dailySavings);
    updatedDailySavings[todayKey] = carbonSaved;
    
    _currentData = _currentData!.copyWith(
      dailySavings: updatedDailySavings,
      totalCarbonSaved: _currentData!.totalCarbonSaved + carbonSaved,
    );
    
    await _saveData();
    return carbonSaved;
  }

  /// Calculate carbon saved from cycling
  static Future<double> calculateCarbonSavedFromCycling(double distanceKm) async {
    if (_currentData == null) await initialize();
    
    final carbonSaved = distanceKm * (_carEmissionFactor - _cyclingEmissionFactor);
    
    // Update daily savings
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    final updatedDailySavings = Map<String, double>.from(_currentData!.dailySavings);
    updatedDailySavings[todayKey] = 
        (updatedDailySavings[todayKey] ?? 0) + carbonSaved;
    
    _currentData = _currentData!.copyWith(
      dailySavings: updatedDailySavings,
      totalCarbonSaved: _currentData!.totalCarbonSaved + carbonSaved,
    );
    
    await _saveData();
    return carbonSaved;
  }

  /// Get today's carbon savings
  static double getTodaysCarbonSavings() {
    if (_currentData == null) return 0.0;
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    return _currentData!.dailySavings[todayKey] ?? 0.0;
  }

  /// Get weekly carbon savings
  static double getWeeklyCarbonSavings() {
    if (_currentData == null) return 0.0;
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    double weeklySavings = 0.0;
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      weeklySavings += _currentData!.dailySavings[dateKey] ?? 0.0;
    }
    
    return weeklySavings;
  }

  /// Get carbon savings history for charts
  static List<Map<String, dynamic>> getCarbonSavingsHistory(int days) {
    if (_currentData == null) return [];
    
    final now = DateTime.now();
    List<Map<String, dynamic>> history = [];
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final savings = _currentData!.dailySavings[dateKey] ?? 0.0;
      
      history.add({
        'date': date,
        'carbonSaved': savings,
        'dateKey': dateKey,
      });
    }
    
    return history;
  }

  /// Compare transportation methods
  static Map<String, dynamic> compareTransportationMethods(double distanceKm) {
    return {
      'walking': {
        'carbonEmission': distanceKm * _walkingEmissionFactor,
        'timeMinutes': (distanceKm / _averageWalkingSpeed) * 60,
        'calories': distanceKm * 50, // Approximate calories burned
        'cost': 0.0,
      },
      'cycling': {
        'carbonEmission': distanceKm * _cyclingEmissionFactor,
        'timeMinutes': (distanceKm / 15.0) * 60, // 15 km/h average cycling
        'calories': distanceKm * 35,
        'cost': 0.0,
      },
      'publicBus': {
        'carbonEmission': distanceKm * _busEmissionFactor,
        'timeMinutes': (distanceKm / 25.0) * 60, // 25 km/h average bus
        'calories': 0,
        'cost': distanceKm * 0.15, // Approximate cost per km
      },
      'car': {
        'carbonEmission': distanceKm * _carEmissionFactor,
        'timeMinutes': (distanceKm / 40.0) * 60, // 40 km/h average city driving
        'calories': 0,
        'cost': distanceKm * 0.25, // Fuel + maintenance cost per km
      },
    };
  }

  /// Get eco-achievements
  static List<Map<String, dynamic>> getEcoAchievements() {
    if (_currentData == null) return [];
    
    final totalSaved = _currentData!.totalCarbonSaved;
    List<Map<String, dynamic>> achievements = [];
    
    if (totalSaved >= 1.0) {
      achievements.add({
        'title': 'Carbon Saver',
        'description': 'Saved 1 kg of CO₂',
        'icon': '🌱',
        'unlocked': true,
      });
    }
    
    if (totalSaved >= 10.0) {
      achievements.add({
        'title': 'Eco Warrior',
        'description': 'Saved 10 kg of CO₂',
        'icon': '🌍',
        'unlocked': true,
      });
    }
    
    if (totalSaved >= 50.0) {
      achievements.add({
        'title': 'Planet Protector',
        'description': 'Saved 50 kg of CO₂',
        'icon': '🏆',
        'unlocked': true,
      });
    }
    
    if (totalSaved >= 100.0) {
      achievements.add({
        'title': 'Climate Champion',
        'description': 'Saved 100 kg of CO₂',
        'icon': '👑',
        'unlocked': true,
      });
    }
    
    return achievements;
  }

  /// Get equivalent savings in real-world terms
  static Map<String, dynamic> getEquivalentSavings(double carbonKg) {
    return {
      'treesPlanted': (carbonKg / 21.0).round(), // 1 tree absorbs ~21kg CO₂/year
      'kmDriving': (carbonKg / _carEmissionFactor).round(),
      'phoneCharges': (carbonKg / 0.008).round(), // 8g CO₂ per phone charge
      'lightBulbHours': (carbonKg / 0.04).round(), // 40g CO₂ per hour LED bulb
    };
  }

  /// Set user preferences for comparisons
  static Future<void> setUserPreferences({
    String? primaryTransport,
    String? location,
    bool? showDailyTips,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_preferencesKey);
    Map<String, dynamic> preferences = current != null ? jsonDecode(current) : {};
    
    if (primaryTransport != null) preferences['primaryTransport'] = primaryTransport;
    if (location != null) preferences['location'] = location;
    if (showDailyTips != null) preferences['showDailyTips'] = showDailyTips;
    
    await prefs.setString(_preferencesKey, jsonEncode(preferences));
  }

  /// Get daily eco tip
  static String getDailyEcoTip() {
    final tips = [
      'Walking 10,000 steps saves about 2kg of CO₂ compared to driving!',
      'Taking stairs instead of elevators saves energy and burns calories.',
      'Cycling is 10x more carbon efficient than driving.',
      'Public transport produces 45% less CO₂ per passenger than private cars.',
      'Walking meetings can reduce your carbon footprint while boosting creativity!',
      'Short trips under 3km are perfect for walking or cycling.',
      'Every step counts towards a healthier planet and a healthier you!',
    ];
    
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return tips[dayOfYear % tips.length];
  }
}

class CarbonFootprintData {
  final double totalCarbonSaved;
  final Map<String, double> dailySavings;
  final DateTime lastUpdated;

  CarbonFootprintData({
    this.totalCarbonSaved = 0.0,
    Map<String, double>? dailySavings,
    DateTime? lastUpdated,
  }) : dailySavings = dailySavings ?? {},
        lastUpdated = lastUpdated ?? DateTime.now();

  CarbonFootprintData copyWith({
    double? totalCarbonSaved,
    Map<String, double>? dailySavings,
    DateTime? lastUpdated,
  }) {
    return CarbonFootprintData(
      totalCarbonSaved: totalCarbonSaved ?? this.totalCarbonSaved,
      dailySavings: dailySavings ?? this.dailySavings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory CarbonFootprintData.fromJson(Map<String, dynamic> json) {
    return CarbonFootprintData(
      totalCarbonSaved: (json['totalCarbonSaved'] ?? 0.0).toDouble(),
      dailySavings: Map<String, double>.from(json['dailySavings'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCarbonSaved': totalCarbonSaved,
      'dailySavings': dailySavings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
