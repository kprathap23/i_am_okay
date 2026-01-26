import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/custom_button.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/landing_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay to ensure text readability
          Container(
            color: Colors.white.withOpacity(0.3),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo
              Center(
                child: SvgPicture.asset(
                  'assets/icons/landing_logo.svg',
                  height: 100, // Adjust height as needed to match previous icon size
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1F4ED8),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'I Am Okay',
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
                backgroundColor: Colors.white, // White background
                textColor: const Color(0xFF1F4ED8), // Deep Blue text
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Powered by ',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Color.fromARGB(255, 236, 217, 217),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/icons/infodat-logo-white.webp',
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/icons/Selltis_Logolockup.png',
                    height: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ],
    ),
    );
  }
}
