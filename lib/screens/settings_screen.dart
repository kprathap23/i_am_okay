import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_button.dart';
import '../services/graphql_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import 'landing_screen.dart';
import 'about_us_screen.dart';
import 'daily_reminder_screen.dart';
import 'edit_profile_screen.dart';
import 'support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    // Immediately try to get local data to build a basic UI
    final userId = await _storage.read(key: 'user_id');
    final mobileNumber = await _storage.read(key: 'mobile_number');

    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "User not found locally. Please login again.";
        });
      }
      return;
    }

    // Build a minimal user object for offline display
    if (mounted) {
      setState(() {
        _user = User(id: userId, mobileNumber: mobileNumber ?? '');
        _isLoading = false; // We have enough to show a basic profile
      });
    }

    // Now, try to fetch the full profile from the network
    try {
      final user = await GraphQLService.getUser(userId);
      if (mounted) {
        setState(() {
          _user = user; // Update with full profile data
        });
      }
    } catch (e) {
      // Non-blocking error. The user can still see their basic profile and log out.
      // Optionally, show a snackbar or a small message.
      debugPrint("Failed to fetch full profile: $e");
      if (mounted) {
        // You could set a different state here to show a small warning icon
        // e.g., setState(() { _isOffline = true; });
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Failed to load profile. You may be offline."),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Log Out',
              onPressed: _logout,
              backgroundColor: Colors.red,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 20),
        _buildSectionTitle("User Information"),
        _buildInfoCard(),
        const SizedBox(height: 20),
        _buildSectionTitle("Settings"),
        _buildSettingsCard(),
        const SizedBox(height: 20),
        _buildSectionTitle("Actions"),
        _buildActionsCard(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final fullName =
        "${_user?.name?.firstName ?? ''} ${_user?.name?.lastName ?? ''}".trim();
    final displayName = fullName.isNotEmpty ? fullName : "User";

    return Column(
      children: [
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF1F4ED8).withAlpha((255 * 0.1).toInt()),
            child: const Icon(
              Icons.person,
              size: 60,
              color: Color(0xFF1F4ED8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatPhoneNumber(_user?.mobileNumber ?? ''),
          style: const TextStyle(
            fontSize: 18.0,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final addr = _user?.address;
    final addressParts = addr != null ? [
      addr.address1,
      addr.address2,
      addr.city,
      addr.state,
      addr.zipCode
    ] : [];
    
    final addressStr = addressParts
        .where((s) => s != null && s.isNotEmpty)
        .join(", ");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (_user?.email != null && _user!.email!.isNotEmpty)
            _buildProfileOption(
              icon: Icons.email_outlined,
              title: "Email",
              subtitle: _user!.email!,
            ),
          if (addressStr.isNotEmpty)
            _buildProfileOption(
              icon: Icons.location_on_outlined,
              title: "Address",
              subtitle: addressStr,
            ),
          _buildProfileOption(
            icon: Icons.edit,
            title: "Edit Profile",
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: _user!),
                ),
              );
              if (result == true) {
                _fetchUser();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildProfileOption(
            icon: Icons.timer_outlined,
            title: "Daily Reminder",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const DailyReminderScreen(isOnboarding: false))),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildProfileOption(
            icon: Icons.info_outline,
            title: "About Us",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AboutUsScreen())),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildProfileOption(
            icon: Icons.support_agent,
            title: "Support",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildProfileOption(
            icon: Icons.logout,
            title: "Log Out",
            onTap: _logout,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: textColor ?? const Color(0xFF1F4ED8)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Color(0xFF666666))) : null,
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
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
