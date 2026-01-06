# Big Steppers

A comprehensive fitness and health tracking mobile application built with Flutter that helps users achieve their fitness goals while promoting sustainable transportation through gamification and route tracking.

## Features

### 🏃 Fitness & Workouts
- **Workout Tracking**: Track various types of workouts with detailed exercise data
- **Fitness Goals**: Set and monitor personalized fitness objectives
- **Start Workout**: Begin workout sessions with guided exercises
- **Workout Details**: View comprehensive information about each workout

### 📊 Health Insights
- **Health Platform Integration**: Sync with various health platforms
- **Health Insights Dashboard**: Analyze your fitness progress and health metrics
- **Personalized Recommendations**: Get insights based on your activity data

### 🎮 Gamification
- **Achievement System**: Earn rewards and badges for completing challenges
- **Progress Tracking**: Visualize your fitness journey
- **Motivation Features**: Stay engaged with gamified fitness goals

### 🗺️ Route Tracking
- **GPS Route Tracking**: Record your walking, running, or cycling routes
- **Google Maps Integration**: View routes on interactive maps
- **Carbon Footprint**: Calculate environmental impact of your active transportation

### 🌤️ Weather Integration
- **Weather Information**: Check current weather conditions before workouts
- **Activity Planning**: Plan outdoor activities based on weather forecasts

### 👥 Social Features
- **Social Sharing**: Connect with friends and share achievements
- **Community Engagement**: Join the fitness community

### ⚙️ User Management
- **User Authentication**: Secure sign-in and sign-up with Firebase
- **Account Management**: Edit profile and change password
- **Settings**: Customize app preferences and notifications
- **Reminders**: Set workout reminders to stay on track

## Tech Stack

- **Framework**: Flutter
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
- **APIs**:
  - Google Maps API
  - Weather API
- **State Management**: [Your state management solution]
- **CI/CD**: Codemagic

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode
- Firebase account
- Google Maps API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Big_Steppers.git
cd Big_Steppers
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:
   - Create a new Firebase project
   - Add your `google-services.json` (Android) to `android/app/`
   - Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`
   - Update `firebase_options.dart` with your configuration

4. Configure API keys:
   - Add your Google Maps API key to the appropriate configuration files
   - Set up any other required API keys in the secrets files

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/              # Core utilities and constants
│   ├── const/        # App constants (colors, text, paths)
│   ├── extensions/   # Dart extensions
│   └── service/      # Core services
├── data/             # Data models and repositories
├── screens/          # UI screens and features
└── main.dart         # App entry point
```

## Configuration

### Firebase Setup
The app uses Firebase for authentication and data storage. Ensure you have properly configured:
- Firebase Authentication
- Cloud Firestore
- Firebase Storage (if applicable)

### Environment Variables
Update the following files with your credentials:
- `android/local.properties`
- `android/secrets.properties`

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## CI/CD

This project uses Codemagic for continuous integration and deployment. Configuration is available in `codemagic.yaml`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All contributors who have helped shape this project

## Contact

Project Link: [https://github.com/yourusername/Big_Steppers](https://github.com/yourusername/Big_Steppers)

---

**Note**: Remember to update API keys, Firebase configuration, and other sensitive information before deploying to production.
