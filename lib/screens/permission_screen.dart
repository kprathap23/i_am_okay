import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../widgets/custom_button.dart';
import 'biometric_setup_screen.dart';
import 'home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _exactAlarmGranted = false;

  bool get _allRequiredPermissionsGranted {
    return _notificationGranted && (!Platform.isAndroid || _exactAlarmGranted);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final locationStatus = await Permission.locationWhenInUse.status;
    final exactAlarmStatus = Platform.isAndroid 
        ? await Permission.scheduleExactAlarm.status 
        : PermissionStatus.granted;

    if (mounted) {
      setState(() {
        _notificationGranted = notificationStatus.isGranted;
        _locationGranted = locationStatus.isGranted;
        _exactAlarmGranted = exactAlarmStatus.isGranted;
      });

      if (_allRequiredPermissionsGranted) {
        _navigateToNext();
      }
    }
  }

  Future<void> _requestPermissions() async {
    // Request Notifications
    if (!_notificationGranted) {
      final status = await Permission.notification.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
    }

    // Request Location
    if (!_locationGranted) {
      final status = await Permission.locationWhenInUse.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
    }

    // Request Exact Alarm (Android only)
    if (Platform.isAndroid && !_exactAlarmGranted) {
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
    }

    await _checkPermissions();
  }

  Future<void> _navigateToNext() async {
    const storage = FlutterSecureStorage();
    final biometricEnabled = await storage.read(key: 'biometric_enabled');

    if (!mounted) return;

    if (biometricEnabled != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BiometricSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Center(
                child: SvgPicture.asset(
                  'assets/icons/landing_logo.svg',
                  height: 80,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1F4ED8),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Permissions Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'To ensure your safety and provide the best experience, we need access to the following permissions:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 40),
              
              // Notification Permission Item
              _buildPermissionItem(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                description: 'To remind you to check in daily and ensure you are okay.',
                isGranted: _notificationGranted,
              ),
              
              const SizedBox(height: 24),
              
              // Location Permission Item
              _buildPermissionItem(
                icon: Icons.location_on_outlined,
                title: 'Location (Optional)',
                description: 'To include your current location in emergency alerts sent to your contacts.',
                isGranted: _locationGranted,
              ),

              if (Platform.isAndroid) ...[
                const SizedBox(height: 24),
                // Exact Alarm Permission Item
                _buildPermissionItem(
                  icon: Icons.alarm,
                  title: 'Exact Alarms',
                  description: 'To schedule precise reminders and safety checks.',
                  isGranted: _exactAlarmGranted,
                ),
              ],

              const Spacer(),

              if (!_allRequiredPermissionsGranted)
                CustomButton(
                  text: 'Grant Permissions',
                  onPressed: _requestPermissions,
                ),
              
              const SizedBox(height: 16),
              
              CustomButton(
                text: 'Continue',
                backgroundColor: _allRequiredPermissionsGranted 
                    ? const Color(0xFF1F4ED8) 
                    : const Color(0xFFE0E0E0),
                textColor: _allRequiredPermissionsGranted 
                    ? Colors.white 
                    : const Color(0xFF999999),
                onPressed: () {
                  if (_allRequiredPermissionsGranted) {
                    _navigateToNext();
                  } else {
                    // Optional: Allow user to skip or prompt again
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please grant required permissions to continue.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isGranted ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isGranted ? Colors.green : const Color(0xFF666666),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  if (isGranted)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
