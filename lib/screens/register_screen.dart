import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
        title: const Text(
          'Register',
          style: TextStyle(
            fontSize: 26.0, // Section title: 22-26
            fontWeight: FontWeight.w600, // SemiBold (600)
            color: Color(0xFF000000),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
              ),
              const SizedBox(height: 24.0),
              const CustomTextField(
                label: 'Mobile Number',
                hint: 'Enter your mobile number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24.0),
              const CustomTextField(
                label: 'Address',
                hint: 'Enter your full address',
                maxLines: 3,
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 24.0),
              const CustomTextField(
                label: 'Email',
                hint: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
                isOptional: true,
              ),
              const SizedBox(height: 24.0),
              const CustomTextField(
                label: 'Existing Health Issues',
                hint: 'List any existing health issues',
                maxLines: 3,
                isOptional: true,
              ),
              const SizedBox(height: 40.0),
              CustomButton(
                text: 'Register',
                onPressed: () {
                  // TODO: Implement registration logic
                  // For now, navigate to login screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen(fromRegistration: true)),
                  );
                },
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
