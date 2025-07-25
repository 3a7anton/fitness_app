import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/core/service/fitness_service.dart';
import 'package:fitness_flutter/data/fitness_data.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:async';

class FitnessStatistics extends StatefulWidget {
  const FitnessStatistics({Key? key}) : super(key: key);

  @override
  _FitnessStatisticsState createState() => _FitnessStatisticsState();
}

class _FitnessStatisticsState extends State<FitnessStatistics> {
  int todaySteps = 0;
  double todayCalories = 0.0;
  double todayDistance = 0.0;
  double progressPercentage = 0.0;
  FitnessGoals goals = FitnessGoals();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFitnessData();
    
    // Refresh data every 30 seconds
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadFitnessData();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadFitnessData() async {
    try {
      final steps = await FitnessService.getTodaySteps();
      final progress = await FitnessService.getTodayProgress();
      final fitnessGoals = await FitnessService.getFitnessGoals();
      
      // Calculate calories and distance
      final stepData = StepData(
        date: DateTime.now(),
        steps: steps,
        calories: steps * 0.04 * 70, // Approximate calculation
        distance: steps * 0.0007,
      );

      if (mounted) {
        setState(() {
          todaySteps = steps;
          todayCalories = stepData.calories;
          todayDistance = stepData.distance;
          progressPercentage = progress;
          goals = fitnessGoals;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading fitness data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _createStepCounter(),
          const SizedBox(height: 20),
          _createFitnessMetrics(),
        ],
      ),
    );
  }

  Widget _createStepCounter() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: ColorConstants.white,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.12),
            blurRadius: 5.0,
            spreadRadius: 1.1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 8.0,
            percent: progressPercentage,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  todaySteps.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textBlack,
                  ),
                ),
                Text(
                  'steps',
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorConstants.grey,
                  ),
                ),
              ],
            ),
            progressColor: ColorConstants.primaryColor,
            backgroundColor: ColorConstants.primaryColor.withOpacity(0.2),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 15),
          Text(
            'Goal: ${goals.dailyStepsGoal} steps',
            style: TextStyle(
              fontSize: 16,
              color: ColorConstants.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${(progressPercentage * 100).toInt()}% Complete',
            style: TextStyle(
              fontSize: 14,
              color: progressPercentage >= 1.0 ? Colors.green : ColorConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _createFitnessMetrics() {
    return Row(
      children: [
        Expanded(
          child: _createMetricCard(
            icon: Icons.local_fire_department,
            value: todayCalories.toInt().toString(),
            unit: 'cal',
            label: 'Calories',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _createMetricCard(
            icon: Icons.directions_walk,
            value: todayDistance.toStringAsFixed(1),
            unit: 'km',
            label: 'Distance',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _createMetricCard({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ColorConstants.white,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.12),
            blurRadius: 5.0,
            spreadRadius: 1.1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textBlack,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: ColorConstants.grey,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ColorConstants.grey,
            ),
          ),
        ],
      ),
    );
  }
}
