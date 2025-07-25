import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/core/const/path_constants.dart';
import 'package:fitness_flutter/core/const/text_constants.dart';
import 'package:fitness_flutter/screens/home/page/home_page.dart';
import 'package:fitness_flutter/screens/settings/settings_screen.dart';
import 'package:fitness_flutter/screens/tab_bar/bloc/tab_bar_bloc.dart';
import 'package:fitness_flutter/screens/workouts/page/workouts_page.dart';
import 'package:fitness_flutter/screens/gamification/page/gamification_screen.dart';
import 'package:fitness_flutter/screens/carbon_footprint/carbon_footprint_screen.dart';
import 'package:fitness_flutter/screens/social/social_features_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TabBarPage extends StatelessWidget {
  const TabBarPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TabBarBloc>(
      create: (BuildContext context) => TabBarBloc(),
      child: BlocConsumer<TabBarBloc, TabBarState>(
        listener: (context, state) {},
        buildWhen: (_, currState) =>
            currState is TabBarInitial || currState is TabBarItemSelectedState,
        builder: (context, state) {
          final bloc = BlocProvider.of<TabBarBloc>(context);
          return Scaffold(
            body: _createBody(context, bloc.currentIndex),
            bottomNavigationBar: _createdBottomTabBar(context),
          );
        },
      ),
    );
  }

  Widget _createdBottomTabBar(BuildContext context) {
    final bloc = BlocProvider.of<TabBarBloc>(context);
    return BottomNavigationBar(
      currentIndex: bloc.currentIndex,
      fixedColor: ColorConstants.primaryColor,
      type: BottomNavigationBarType.fixed, // Add this to show all tabs
      selectedFontSize: 10,
      unselectedFontSize: 9,
      items: [
        BottomNavigationBarItem(
          icon: Image(
            image: AssetImage(PathConstants.home),
            color: bloc.currentIndex == 0 ? ColorConstants.primaryColor : null,
          ),
          label: TextConstants.homeIcon,
        ),
        BottomNavigationBarItem(
          icon: Image(
            image: AssetImage(PathConstants.workouts),
            color: bloc.currentIndex == 1 ? ColorConstants.primaryColor : null,
          ),
          label: TextConstants.workoutsIcon,
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.eco,
            color: bloc.currentIndex == 2 ? ColorConstants.primaryColor : null,
          ),
          label: 'Eco',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.group,
            color: bloc.currentIndex == 3 ? ColorConstants.primaryColor : null,
          ),
          label: 'Social',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.star,
            color: bloc.currentIndex == 4 ? ColorConstants.primaryColor : null,
          ),
          label: 'Rewards',
        ),
        BottomNavigationBarItem(
          icon: Image(
            image: AssetImage(PathConstants.settings),
            color: bloc.currentIndex == 5 ? ColorConstants.primaryColor : null,
          ),
          label: TextConstants.settingsIcon,
        ),
      ],
      onTap: (index) {
        bloc.add(TabBarItemTappedEvent(index: index));
      },
    );
  }

  Widget _createBody(BuildContext context, int index) {
    final children = [
      HomePage(),
      WorkoutsPage(),
      CarbonFootprintScreen(),
      SocialFeaturesScreen(),
      GamificationScreen(),
      SettingsScreen()
      // Scaffold(
      //   body: Center(
      //     child: RawMaterialButton(
      //       fillColor: Colors.red,
      //       child: Text(
      //         TextConstants.signOut,
      //         style: TextStyle(
      //           color: ColorConstants.white,
      //         ),
      //       ),
      //       onPressed: () {
      //         AuthService.signOut();
      //         Navigator.pushReplacement(
      //           context,
      //           MaterialPageRoute(builder: (_) => SignInPage()),
      //         );
      //       },
      //     ),
      //   ),
      // ),
    ];
    return children[index];
  }
}
