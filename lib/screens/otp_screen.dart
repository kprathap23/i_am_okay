import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';
import '../services/graphql_service.dart';
import 'emergency_contact_screen.dart';
import 'emergency_contact_dashboard.dart';
import 'daily_reminder_screen.dart';
import 'permission_screen.dart';

class OtpScreen extends StatefulWidget {
  final bool isRegistration;
  final String? mobileNumber;
  final Map<String, dynamic>? userData;
  final String? role;

  const OtpScreen({
    super.key,
    this.isRegistration = false,
    this.mobileNumber,
    this.userData,
    this.role,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 60;
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _canResend = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend || widget.mobileNumber == null) return;

    LoadingOverlay.show(context);
    try {
      await GraphQLService.requestOtp(widget.mobileNumber!);
      
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully')),
        );
        startTimer();
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    if (widget.mobileNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number missing')),
      );
      return;
    }

    LoadingOverlay.show(context);

    try {
      final authPayload = await GraphQLService.verifyOtp(
        widget.mobileNumber!,
        otp,
        userDetails: widget.isRegistration && widget.userData != null
            ? Map<String, dynamic>.from(widget.userData!)
            : null,
        isEmergencyContact: widget.role == 'contact',
      );

      final token = authPayload.token;
      final user = authPayload.user;

      await _storage.write(key: 'auth_token', value: token);
      if (widget.mobileNumber != null) {
        await _storage.write(key: 'mobile_number', value: widget.mobileNumber!);
      }

      if (user != null) {
        await _storage.write(key: 'user_id', value: user.id);
      }
      if (widget.role != null) {
        await _storage.write(key: 'user_role', value: widget.role);
      }

      if (mounted) {
        LoadingOverlay.hide(context);

        if (widget.role == 'contact') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const EmergencyContactDashboard()),
            (route) => false,
          );
          return;
        }

        // Check for missing data in sequence
        bool hasEmergencyContacts = user?.emergencyContacts.isNotEmpty ?? false;
        bool hasReminderSettings = user?.reminderSettings != null;

        if (!hasEmergencyContacts) {
          // Navigate to Emergency Contact Screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const EmergencyContactScreen()),
            (route) => false,
          );
        } else if (!hasReminderSettings) {
          // Navigate to Daily Reminder Screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const DailyReminderScreen()),
            (route) => false,
          );
        } else {
          // All good, go to Permissions then Home
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PermissionScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
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
              CustomTextField(
                label: 'OTP Code',
                hint: 'Enter the 6-digit code',
                keyboardType: TextInputType.number,
                controller: _otpController,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Verify & Login',
                onPressed: _handleVerify,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _canResend ? _handleResendOtp : null,
                  child: Text(
                    _canResend ? 'Resend Code' : 'Resend Code in ${_start}s',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: _canResend ? const Color(0xFF1F4ED8) : Colors.grey,
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
