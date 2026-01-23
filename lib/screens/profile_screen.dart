import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'landing_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF1F4ED8),
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'User Name',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              '+1 234 567 8900',
              style: TextStyle(
                fontSize: 18.0,
                color: Color(0xFF333333),
              ),
            ),
            const Spacer(),
            CustomButton(
              text: 'Log Out',
              onPressed: () {
                // Navigate back to LandingScreen and remove all previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingScreen()),
                  (route) => false,
                );
              },
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
