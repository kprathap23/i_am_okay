import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';
import '../services/graphql_service.dart';
import '../utils/phone_input_formatter.dart';
import 'register_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool fromRegistration;
  final String? initialMobileNumber;

  const LoginScreen({
    super.key,
    this.fromRegistration = false,
    this.initialMobileNumber,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialMobileNumber != null) {
      _mobileController.text = widget.initialMobileNumber!;
    }
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawMobile = _mobileController.text;
    final mobile = rawMobile.replaceAll(RegExp(r'\D'), '');

    LoadingOverlay.show(context);

    try {
      // ignore: unused_local_variable
      final result = await GraphQLService.requestOtp(mobile);

      if (mounted) {
        LoadingOverlay.hide(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              isRegistration: false,
              mobileNumber: mobile,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);

        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('not found')) {
          _showAccountNotFoundDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAccountNotFoundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Not Found'),
        content: const Text(
            'We could not find an account with this mobile number. Would you like to create a new account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Health Related Logo
              Center(
                child: SvgPicture.asset(
                  'assets/icons/landing_logo.svg',
                  height: 100,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1F4ED8),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  widget.fromRegistration ? 'Welcome' : 'Welcome Back',
                  style: const TextStyle(
                    fontSize: 28.0, // Main heading
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Sign in to continue to your account',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              CustomTextField(
                label: 'Mobile Number',
                hint: 'Enter your mobile number',
                keyboardType: TextInputType.phone,
                controller: _mobileController,
                inputFormatters: [PhoneInputFormatter()],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleLogin(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 10) {
                    return 'Please enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Sign In',
                onPressed: () => _handleLogin(context),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Color(0xFF333333),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F4ED8),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
