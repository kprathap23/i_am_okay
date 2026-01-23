import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'emergency_contact_screen.dart';
// import 'home_screen.dart'; // Uncomment when needed

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000000)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Color(0xFF1F4ED8),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Verification',
                  style: TextStyle(
                    fontSize: 28.0, // Main heading
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'We have sent a one-time password to your mobile number.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const CustomTextField(
                label: 'OTP Code',
                hint: 'Enter the 6-digit code',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Verify',
                onPressed: () {
                  // TODO: Implement OTP verification logic
                  // Navigate to home screen or dashboard
                  
                  // Simulating first time user logic:
                  // If first time -> EmergencyContactScreen
                  // Else -> HomeScreen
                  
                  // For demonstration, we navigate to EmergencyContactScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmergencyContactScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Resend OTP logic
                  },
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F4ED8),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
