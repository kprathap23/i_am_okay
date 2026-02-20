import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:IamOkay/screens/emergency_contact_dashboard.dart';
import 'package:IamOkay/screens/home_screen.dart';
import 'package:IamOkay/widgets/custom_button.dart';
import 'package:local_auth/local_auth.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final localAuth = LocalAuthentication();
    try {
      final isAvailable = await localAuth.canCheckBiometrics &&
          await localAuth.isDeviceSupported();
      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
        });
      }
    }
  }

  Future<void> _handleEnableBiometric() async {
    final localAuth = LocalAuthentication();
    bool authenticated = false;
    try {
      authenticated = await localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
      );
    } catch (e) {
      // Handle error
    }

    if (authenticated) {
      await _storage.write(key: 'biometric_enabled', value: 'true');
      _navigateToDashboard();
    } else {
      // Optionally, show a message that authentication failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _skipBiometric() async {
    await _storage.write(key: 'biometric_enabled', value: 'false');
    _navigateToDashboard();
  }

  void _navigateToDashboard() async {
    final userRole = await _storage.read(key: 'user_role');
    if (mounted) {
      if (userRole == 'contact') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const EmergencyContactDashboard(),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.fingerprint,
                size: 80,
                color: Color(0xFF1F4ED8),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enable Biometric Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log in faster and more securely with your fingerprint or face.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Color(0xFF666666),
                ),
              ),
              const Spacer(),
              if (_isBiometricAvailable)
                CustomButton(
                  text: 'Enable Biometric Login',
                  onPressed: _handleEnableBiometric,
                )
              else
                const Text(
                  'Biometrics not available on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _skipBiometric,
                child: const Text(
                  'Skip for Now',
                  style: TextStyle(
                    color: Color(0xFF1F4ED8),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
