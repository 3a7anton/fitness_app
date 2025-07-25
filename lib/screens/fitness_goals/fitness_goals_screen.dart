import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/core/service/fitness_service.dart';
import 'package:fitness_flutter/data/fitness_data.dart';
import 'package:fitness_flutter/screens/common_widgets/fitness_button.dart';
import 'package:flutter/material.dart';

class FitnessGoalsScreen extends StatefulWidget {
  const FitnessGoalsScreen({Key? key}) : super(key: key);

  @override
  _FitnessGoalsScreenState createState() => _FitnessGoalsScreenState();
}

class _FitnessGoalsScreenState extends State<FitnessGoalsScreen> {
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _distanceController = TextEditingController();
  final _workoutsController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }

  Future<void> _loadCurrentGoals() async {
    try {
      final goals = await FitnessService.getFitnessGoals();
      final physicalData = await FitnessService.getUserPhysicalData();

      setState(() {
        _stepsController.text = goals.dailyStepsGoal.toString();
        _caloriesController.text = goals.dailyCaloriesGoal.toString();
        _distanceController.text = goals.dailyDistanceGoal.toString();
        _workoutsController.text = goals.weeklyWorkoutsGoal.toString();
        _weightController.text = physicalData['weight']?.toString() ?? '';
        _heightController.text = physicalData['height']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGoals() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final goals = FitnessGoals(
        dailyStepsGoal: int.tryParse(_stepsController.text) ?? 10000,
        dailyCaloriesGoal: double.tryParse(_caloriesController.text) ?? 500.0,
        dailyDistanceGoal: double.tryParse(_distanceController.text) ?? 5.0,
        weeklyWorkoutsGoal: int.tryParse(_workoutsController.text) ?? 5,
      );

      await FitnessService.saveFitnessGoals(goals);

      final weight = double.tryParse(_weightController.text);
      final height = double.tryParse(_heightController.text);
      
      await FitnessService.saveUserPhysicalData(
        weight: weight,
        height: height,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goals updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving goals: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fitness Goals',
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
                  _buildSectionTitle('Daily Goals'),
                  const SizedBox(height: 15),
                  _buildGoalField(
                    controller: _stepsController,
                    label: 'Daily Steps Goal',
                    suffix: 'steps',
                    icon: Icons.directions_walk,
                  ),
                  const SizedBox(height: 15),
                  _buildGoalField(
                    controller: _caloriesController,
                    label: 'Daily Calories Goal',
                    suffix: 'cal',
                    icon: Icons.local_fire_department,
                  ),
                  const SizedBox(height: 15),
                  _buildGoalField(
                    controller: _distanceController,
                    label: 'Daily Distance Goal',
                    suffix: 'km',
                    icon: Icons.map,
                  ),
                  const SizedBox(height: 30),
                  
                  _buildSectionTitle('Weekly Goals'),
                  const SizedBox(height: 15),
                  _buildGoalField(
                    controller: _workoutsController,
                    label: 'Weekly Workouts Goal',
                    suffix: 'workouts',
                    icon: Icons.fitness_center,
                  ),
                  const SizedBox(height: 30),
                  
                  _buildSectionTitle('Personal Information'),
                  const SizedBox(height: 15),
                  _buildGoalField(
                    controller: _weightController,
                    label: 'Weight',
                    suffix: 'kg',
                    icon: Icons.monitor_weight,
                  ),
                  const SizedBox(height: 15),
                  _buildGoalField(
                    controller: _heightController,
                    label: 'Height',
                    suffix: 'cm',
                    icon: Icons.height,
                  ),
                  
                  const SizedBox(height: 40),
                  FitnessButton(
                    title: _isSaving ? 'Saving...' : 'Save Goals',
                    isEnabled: !_isSaving,
                    onTap: _saveGoals,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: ColorConstants.textBlack,
      ),
    );
  }

  Widget _buildGoalField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ColorConstants.white,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.08),
            blurRadius: 3.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: ColorConstants.primaryColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          labelStyle: TextStyle(color: ColorConstants.grey),
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _distanceController.dispose();
    _workoutsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
}
