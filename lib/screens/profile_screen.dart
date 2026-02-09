import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_button.dart';
import '../services/graphql_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import 'landing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "User not found locally. Please login again.";
          });
        }
        return;
      }

      final user = await GraphQLService.getUser(userId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1F4ED8),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              if (_errorMessage!.contains("login again"))
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F4ED8),
                  ),
                  child: const Text('Go to Login'),
                ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const Center(child: Text("Failed to load profile"));
    }

    final fullName =
        "${_user?.name?.firstName ?? ''} ${_user?.name?.lastName ?? ''}".trim();
    final displayName = fullName.isNotEmpty ? fullName : "User";

    return Padding(
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
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatPhoneNumber(_user?.mobileNumber ?? ''),
            style: const TextStyle(
              fontSize: 18.0,
              color: Color(0xFF333333),
            ),
          ),
          if (_user?.email != null && _user!.email!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _user!.email!,
              style: const TextStyle(
                fontSize: 16.0,
                color: Color(0xFF666666),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildInfoCard(),
          const Spacer(),
          CustomButton(
            text: 'Log Out',
            onPressed: _logout,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    if (_user?.address == null) return const SizedBox.shrink();

    final addr = _user!.address!;
    final addressParts = [
      addr.address1,
      addr.address2,
      addr.city,
      addr.state,
      addr.zipCode
    ];
    
    final addressStr = addressParts
        .where((s) => s != null && s.isNotEmpty)
        .join(", ");

    if (addressStr.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: Color(0xFF1F4ED8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              addressStr,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // Check if it starts with 1 (US country code) and has 11 digits, remove the 1
    if (digits.length == 11 && digits.startsWith('1')) {
      digits = digits.substring(1);
    }

    // If we have 10 digits, format it
    if (digits.length == 10) {
      return '+1 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    // Fallback to original or return empty if input was empty
    return phone;
  }

  Future<void> _logout() async {
    // Cancel all notifications on logout
    await NotificationService().cancelAllNotifications();

    await _storage.deleteAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (route) => false,
      );
    }
  }
}
