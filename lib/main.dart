import 'package:firebase_core/firebase_core.dart';
import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/core/service/notification_service.dart';
import 'package:fitness_flutter/core/service/fitness_service.dart';
import 'package:fitness_flutter/core/service/health_platform_service.dart';
import 'package:fitness_flutter/core/service/location_tracking_service.dart';
import 'package:fitness_flutter/screens/tab_bar/page/tab_bar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  
  // Initialize Firebase only if not already initialized
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print('Firebase already initialized: $e');
  }
  
  // Initialize fitness tracking
  try {
    await FitnessService.initialize();
    print('Fitness service initialized successfully');
  } catch (e) {
    print('Error initializing fitness service: $e');
  }

  // Initialize health platform service
  try {
    await HealthPlatformService.initialize();
    print('Health platform service initialized successfully');
  } catch (e) {
    print('Error initializing health platform service: $e');
  }

  // Initialize location tracking service
  try {
    await LocationTrackingService.initialize();
    print('Location tracking service initialized successfully');
  } catch (e) {
    print('Error initializing location tracking service: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = NotificationService.flutterLocalNotificationsPlugin;

  @override
  initState() {
    super.initState();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    tz.initializeTimeZones();

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await selectNotification(response.payload);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Skip authentication for testing - go directly to main app
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BigSteppers',
      theme: ThemeData(
        textTheme: TextTheme(bodyLarge: TextStyle(color: ColorConstants.textColor)),
        fontFamily: 'NotoSansKR',
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TabBarPage(), // Skip to main app with fitness features
    );
  }

  Future selectNotification(String? payload) async {
    showDialog(
      context: context,
      builder: (_) {
        return new AlertDialog(
          title: Text("PayLoad"),
          content: Text("Payload : $payload"),
        );
      },
    );
  }
}
