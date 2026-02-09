import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/landing_screen.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await BackgroundService().init();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IAmOkay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // White
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4ED8), // Deep Blue
          primary: const Color(0xFF1F4ED8),
          surface: const Color(0xFFFFFFFF),
        ),
        fontFamily: 'Roboto', // Default flutter font, but explicit is good. Or just rely on default.
        textTheme: const TextTheme(
          // Main heading: 28–34
          displayLarge: TextStyle(
            fontSize: 34.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
          displayMedium: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
          // Section title: 22–26
          titleLarge: TextStyle(
            fontSize: 26.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
          titleMedium: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
          // Body text: 18–20
          bodyLarge: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
          bodyMedium: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w400,
            color: Color(0xFF333333), // Secondary text color for body medium often makes sense
          ),
          // Button text: 18–22
          labelLarge: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
            color: Color(0xFFFFFFFF),
          ),
        ),
        useMaterial3: true,
      ),
      home: const LandingScreen(),
    );
  }
}
