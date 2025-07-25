import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/core/service/fitness_service.dart';
import 'package:fitness_flutter/data/fitness_data.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({Key? key}) : super(key: key);

  @override
  _HealthInsightsScreenState createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen> {
  bool _isLoading = true;
  double? _bmi;
  String _healthStatus = '';
  String _motivationalMessage = '';
  double _weeklyAverageSteps = 0;
  List<StepData> _weeklyData = [];

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      final physicalData = await FitnessService.getUserPhysicalData();
      final weeklyAverage = await FitnessService.getWeeklyAverageSteps();
      final stepHistory = await FitnessService.getStepHistory();
      
      final weight = physicalData['weight'];
      final height = physicalData['height'];
      
      final insights = HealthInsights.fromStepData(
        stepHistory,
        weight: weight,
        height: height,
      );

      setState(() {
        _bmi = insights.bmi;
        _healthStatus = insights.healthStatus;
        _motivationalMessage = insights.motivationalMessage;
        _weeklyAverageSteps = weeklyAverage;
        _weeklyData = stepHistory.take(7).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Health Insights',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMotivationalCard(),
                  const SizedBox(height: 20),
                  _buildBMICard(),
                  const SizedBox(height: 20),
                  _buildWeeklyStatsCard(),
                  const SizedBox(height: 20),
                  _buildStepsChart(),
                  const SizedBox(height: 20),
                  _buildHealthTips(),
                ],
              ),
            ),
    );
  }

  Widget _buildMotivationalCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [ColorConstants.primaryColor, ColorConstants.primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.favorite,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            'Keep Going!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _motivationalMessage,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMICard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: ColorConstants.white,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.08),
            blurRadius: 8.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_weight,
                color: ColorConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Body Mass Index',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_bmi != null && _bmi! > 0) ...[
            Row(
              children: [
                Text(
                  _bmi!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'kg/m²',
                  style: TextStyle(
                    fontSize: 16,
                    color: ColorConstants.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Status: $_healthStatus',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _getHealthStatusColor(),
              ),
            ),
          ] else ...[
            Text(
              'Set your weight and height in Goals to see BMI',
              style: TextStyle(
                fontSize: 14,
                color: ColorConstants.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getHealthStatusColor() {
    switch (_healthStatus.toLowerCase()) {
      case 'normal weight':
        return Colors.green;
      case 'overweight':
        return Colors.orange;
      case 'obese':
        return Colors.red;
      case 'underweight':
        return Colors.blue;
      default:
        return ColorConstants.grey;
    }
  }

  Widget _buildWeeklyStatsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: ColorConstants.white,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.08),
            blurRadius: 8.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: ColorConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Weekly Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Avg Steps',
                  _weeklyAverageSteps.toInt().toString(),
                  Icons.directions_walk,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Best Day',
                  _weeklyData.isEmpty ? '0' : _weeklyData.map((e) => e.steps).reduce((a, b) => a > b ? a : b).toString(),
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ColorConstants.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorConstants.textBlack,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ColorConstants.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsChart() {
    if (_weeklyData.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No data available for chart',
            style: TextStyle(color: ColorConstants.grey),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: ColorConstants.white,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.08),
            blurRadius: 8.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Steps Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorConstants.textBlack,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.steps.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: ColorConstants.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: ColorConstants.primaryColor.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTips() {
    final tips = [
      'Try to walk at least 10,000 steps daily for optimal health',
      'Take regular breaks from sitting every 30 minutes',
      'Stay hydrated - drink 8 glasses of water per day',
      'Combine cardio with strength training for best results',
      'Get 7-9 hours of quality sleep each night',
    ];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: ColorConstants.white,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.08),
            blurRadius: 8.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: ColorConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Health Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...tips.map((tip) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: ColorConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConstants.textBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
