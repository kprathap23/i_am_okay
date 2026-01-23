import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // White background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo
              const Icon(
                Icons.health_and_safety,
                size: 100,
                color: Color(0xFF1F4ED8),
              ),
              const Center(
                child: Text(
                  'IAmOkay',
                  style: TextStyle(
                    fontSize: 34.0, // Main heading: 28-34
                    fontWeight: FontWeight.w600, // SemiBold (600)
                    color: Color(0xFF000000), // Primary Text
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Welcome to your personal safety companion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.0, // Body text: 18-20
                    fontWeight: FontWeight.w400, // Regular (400)
                    color: Color(0xFF333333), // Secondary Text
                  ),
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'I already have an account',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                backgroundColor: Colors.transparent, // Variant for secondary action
                textColor: const Color(0xFF1F4ED8), // Deep Blue text
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
