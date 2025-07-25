import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/core/const/data_constants.dart';
import 'package:fitness_flutter/core/const/path_constants.dart';
import 'package:fitness_flutter/core/const/text_constants.dart';
import 'package:fitness_flutter/screens/edit_account/edit_account_screen.dart';
import 'package:fitness_flutter/screens/home/bloc/home_bloc.dart';
import 'package:fitness_flutter/screens/home/widget/home_statistics.dart';
import 'package:fitness_flutter/screens/home/widget/fitness_statistics.dart';
import 'package:fitness_flutter/screens/workout_details_screen/page/workout_details_page.dart';
import 'package:fitness_flutter/screens/fitness_goals/fitness_goals_screen.dart';
import 'package:fitness_flutter/screens/health_insights/health_insights_screen.dart';
import 'package:fitness_flutter/screens/weather/weather_screen.dart';
import 'package:fitness_flutter/screens/route_tracking/route_tracking_screen.dart';
import 'package:fitness_flutter/screens/health_platform/health_platform_screen.dart';
import 'package:fitness_flutter/screens/carbon_footprint/carbon_footprint_screen.dart';
import 'package:fitness_flutter/screens/social/social_features_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_exercises_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorConstants.homeBackgroundColor,
      height: double.infinity,
      width: double.infinity,
      child: _createHomeBody(context),
    );
  }

  Widget _createHomeBody(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _createProfileData(context),
          const SizedBox(height: 35),
          FitnessStatistics(),
          const SizedBox(height: 20),
          _createFitnessActions(context),
          const SizedBox(height: 20),
          HomeStatistics(),
          const SizedBox(height: 30),
          _createExercisesList(context),
          const SizedBox(height: 25),
          _createProgress(),
        ],
      ),
    );
  }

  Widget _createExercisesList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            TextConstants.discoverWorkouts,
            style: TextStyle(
              color: ColorConstants.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 20),
              WorkoutCard(
                  color: ColorConstants.cardioColor,
                  workout: DataConstants.homeWorkouts[0],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WorkoutDetailsPage(
                            workout: DataConstants.workouts[0],
                          )))),
              const SizedBox(width: 15),
              WorkoutCard(
                  color: ColorConstants.armsColor,
                  workout: DataConstants.homeWorkouts[1],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WorkoutDetailsPage(
                            workout: DataConstants.workouts[2],
                          )))),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createProfileData(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "No Username";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $displayName',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                TextConstants.checkActivity,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (_, currState) => currState is ReloadImageState,
            builder: (context, state) {
              final photoUrl =
                  FirebaseAuth.instance.currentUser?.photoURL ?? null;
              return GestureDetector(
                child: photoUrl == null
                    ? CircleAvatar(
                        backgroundImage: AssetImage(PathConstants.profile),
                        radius: 60)
                    : CircleAvatar(
                        child: ClipOval(
                            child: FadeInImage.assetNetwork(
                                placeholder: PathConstants.profile,
                                image: photoUrl,
                                fit: BoxFit.cover,
                                width: 200,
                                height: 120)),
                        radius: 25),
                onTap: () async {
                  await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EditAccountScreen()));
                  BlocProvider.of<HomeBloc>(context).add(ReloadImageEvent());
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _createProgress() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
      child: Row(
        children: [
          Image(
            image: AssetImage(
              PathConstants.progress,
            ),
          ),
          SizedBox(width: 20),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TextConstants.keepProgress,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  TextConstants.profileSuccessful,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createFitnessActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _createActionButton(
                  context,
                  'Set Goals',
                  Icons.flag,
                  ColorConstants.primaryColor,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FitnessGoalsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _createActionButton(
                  context,
                  'Health Insights',
                  Icons.insights,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HealthInsightsScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _createActionButton(
                  context,
                  'Weather',
                  Icons.wb_sunny,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WeatherScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _createActionButton(
                  context,
                  'Route Track',
                  Icons.map,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RouteTrackingScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _createActionButton(
                  context,
                  'Health Sync',
                  Icons.health_and_safety,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HealthPlatformScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _createActionButton(
                  context,
                  'Carbon Impact',
                  Icons.eco,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CarbonFootprintScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _createActionButton(
                  context,
                  'Social Fitness',
                  Icons.group,
                  ColorConstants.primaryColor,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SocialFeaturesScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Container(), // Empty space for symmetry
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _createActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: ColorConstants.white,
          boxShadow: [
            BoxShadow(
              color: ColorConstants.textBlack.withOpacity(0.08),
              blurRadius: 5.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorConstants.textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
