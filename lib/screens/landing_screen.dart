import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_button.dart';
import '../services/biometric_service.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import 'permission_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricLogin();
    });
  }

  Future<void> _checkBiometricLogin() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    debugPrint('Checking biometric login. Token exists: ${token != null}');

    if (token != null) {
      // Small delay to let the UI render and animation start
      await Future.delayed(const Duration(milliseconds: 500));

      final isAvailable = await BiometricService.isBiometricAvailable();
      debugPrint('Biometric available: $isAvailable');

      if (isAvailable && mounted) {
        final authenticated = await BiometricService.authenticate();
        debugPrint('Authentication result: $authenticated');
        
        if (authenticated && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PermissionScreen()),
          );
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Authentication failed or cancelled')),
           );
        }
      } else if (mounted) {
         debugPrint('Biometrics not available on this device');
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Biometrics not available. Please login again.')),
         );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
            color: Colors.white.withValues(alpha: 0.3),
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
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SvgPicture.asset(
                          'assets/icons/landing_logo.svg',
                          height: 100, // Adjust height as needed to match previous icon size
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF1F4ED8),
                            BlendMode.srcIn,
                          ),
                        ),
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
