import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'emergency_contact_screen.dart';
import 'login_screen.dart';

class OtpScreen extends StatelessWidget {
  final bool isRegistration;

  const OtpScreen({
    super.key,
    this.isRegistration = false,
  });

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

                  if (isRegistration) {
                    // If from registration, navigate to Login Screen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false, // Remove all previous routes
                    );
                  } else {
                    // If from login, navigate to Emergency Contacts (or Home if not first time)
                    // Assuming for now it goes to EmergencyContactScreen as requested
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const EmergencyContactScreen()),
                      (route) => false, // Remove all previous routes
                    );
                  }
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
