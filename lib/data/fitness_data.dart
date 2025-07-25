class StepData {
  final DateTime date;
  final int steps;
  final double calories;
  final double distance; // in kilometers

  StepData({
    required this.date,
    required this.steps,
    required this.calories,
    required this.distance,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'calories': calories,
      'distance': distance,
    };
  }

  factory StepData.fromJson(Map<String, dynamic> json) {
    return StepData(
      date: DateTime.parse(json['date']),
      steps: json['steps'],
      calories: json['calories'],
      distance: json['distance'],
    );
  }
}

class FitnessGoals {
  final int dailyStepsGoal;
  final double dailyCaloriesGoal;
  final double dailyDistanceGoal;
  final int weeklyWorkoutsGoal;

  FitnessGoals({
    this.dailyStepsGoal = 10000,
    this.dailyCaloriesGoal = 500.0,
    this.dailyDistanceGoal = 5.0,
    this.weeklyWorkoutsGoal = 5,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailyStepsGoal': dailyStepsGoal,
      'dailyCaloriesGoal': dailyCaloriesGoal,
      'dailyDistanceGoal': dailyDistanceGoal,
      'weeklyWorkoutsGoal': weeklyWorkoutsGoal,
    };
  }

  factory FitnessGoals.fromJson(Map<String, dynamic> json) {
    return FitnessGoals(
      dailyStepsGoal: json['dailyStepsGoal'] ?? 10000,
      dailyCaloriesGoal: json['dailyCaloriesGoal'] ?? 500.0,
      dailyDistanceGoal: json['dailyDistanceGoal'] ?? 5.0,
      weeklyWorkoutsGoal: json['weeklyWorkoutsGoal'] ?? 5,
    );
  }
}

class HealthInsights {
  final double bmi;
  final String healthStatus;
  final int weeklyAverageSteps;
  final double weeklyAverageCalories;
  final String motivationalMessage;

  HealthInsights({
    required this.bmi,
    required this.healthStatus,
    required this.weeklyAverageSteps,
    required this.weeklyAverageCalories,
    required this.motivationalMessage,
  });

  factory HealthInsights.fromStepData(List<StepData> weeklyData, {double? weight, double? height}) {
    double averageSteps = weeklyData.isEmpty ? 0 : 
        weeklyData.map((e) => e.steps).reduce((a, b) => a + b) / weeklyData.length;
    double averageCalories = weeklyData.isEmpty ? 0 : 
        weeklyData.map((e) => e.calories).reduce((a, b) => a + b) / weeklyData.length;
    
    double bmi = 0.0;
    String healthStatus = "No data";
    String motivationalMessage = "Keep moving!";

    if (weight != null && height != null && height > 0) {
      bmi = weight / ((height / 100) * (height / 100));
      
      if (bmi < 18.5) {
        healthStatus = "Underweight";
        motivationalMessage = "Consider building muscle with strength training!";
      } else if (bmi < 25) {
        healthStatus = "Normal weight";
        motivationalMessage = "Great job maintaining a healthy weight!";
      } else if (bmi < 30) {
        healthStatus = "Overweight";
        motivationalMessage = "Stay active and maintain a balanced diet!";
      } else {
        healthStatus = "Obese";
        motivationalMessage = "Every step counts towards better health!";
      }
    }

    if (averageSteps < 5000) {
      motivationalMessage = "Try to increase your daily activity!";
    } else if (averageSteps > 10000) {
      motivationalMessage = "Excellent! You're exceeding daily recommendations!";
    }

    return HealthInsights(
      bmi: bmi,
      healthStatus: healthStatus,
      weeklyAverageSteps: averageSteps.round(),
      weeklyAverageCalories: averageCalories,
      motivationalMessage: motivationalMessage,
    );
  }
}
