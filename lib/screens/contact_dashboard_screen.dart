import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/graphql_service.dart';
import 'landing_screen.dart';

class ContactDashboardScreen extends StatefulWidget {
  const ContactDashboardScreen({super.key});

  @override
  State<ContactDashboardScreen> createState() => _ContactDashboardScreenState();
}

class _ContactDashboardScreenState extends State<ContactDashboardScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  List<User> _usersWhoAddedMe = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        _handleLogout();
        return;
      }

      // 1. Get current user to know my phone number
      final user = await GraphQLService.getUser(userId);
      if (user == null) {
        _handleLogout();
        return;
      }

      // 2. Get users who have added me as emergency contact
      // Filtering locally because 'emergencyContacts' field does not exist on UserQueryInput
      final allUsers = await GraphQLService.getDashboardUsers();
      
      final users = allUsers.toList();

      if (mounted) {
        setState(() {
          _usersWhoAddedMe = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await _storage.deleteAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Dashboard'),
        backgroundColor: const Color(0xFF1F4ED8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usersWhoAddedMe.isEmpty
              ? const Center(
                  child: Text(
                    'No users have added you as an emergency contact yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _usersWhoAddedMe.length,
                  itemBuilder: (context, index) {
                    final user = _usersWhoAddedMe[index];
                    final name = user.name?.firstName ?? 'Unknown';
                    final phone = user.mobileNumber;
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1F4ED8),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text('$name ${user.name?.lastName ?? ''}'),
                        subtitle: Text(phone),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Potential future feature: View detailed status history
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
