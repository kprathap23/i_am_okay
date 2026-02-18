import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:i_am_okay/models/user_model.dart';
import 'package:i_am_okay/screens/history_screen.dart';
import 'package:i_am_okay/screens/landing_screen.dart';
import '../services/notification_service.dart';
import '../services/graphql_service.dart';

class EmergencyContactDashboard extends StatefulWidget {
  const EmergencyContactDashboard({super.key});

  @override
  State<EmergencyContactDashboard> createState() =>
      _EmergencyContactDashboardState();
}

class _EmergencyContactDashboardState extends State<EmergencyContactDashboard> {
  final _storage = const FlutterSecureStorage();
  Future<List<User>>? _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    final mobile = await _storage.read(key: 'mobile_number');
    if (mobile == null) {
      throw Exception('Mobile number not found');
    }

    final allUsers = await GraphQLService.getUsers();

    final relevantUsers = allUsers.where((user) {
      return user.emergencyContacts.any((contact) => contact.phone == mobile);
    }).toList();

    return relevantUsers;
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = _fetchUsers();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Emergency Contact For'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F4ED8),
        elevation: 1,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/icons/app_icon.png'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<User>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error);
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final users = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final name = user.name;
    final address = user.address;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(
                      '${name?.firstName ?? ''} ${name?.lastName ?? ''}\'s History'),
                  backgroundColor: const Color(0xFF1F4ED8),
                  foregroundColor: Colors.white,
                ),
                body: HistoryScreen(
                  contactId: user.id,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.primaryColor.withAlpha(26),
                    child: Text(
                      '${name?.firstName?[0] ?? ''}${name?.lastName?[0] ?? ''}'.toUpperCase(),
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${name?.firstName ?? ''} ${name?.lastName ?? ''}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (address?.city != null && address?.state != null)
                          Text(
                            '${address!.city}, ${address.state}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mobile Number', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(user.mobileNumber, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement call functionality
                    },
                    icon: Icon(Icons.call, color: theme.primaryColor),
                    label: Text('Call', style: TextStyle(color: theme.primaryColor)),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No One Has Added You',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You are not listed as an emergency contact for anyone at the moment.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Something Went Wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t fetch the data. Please try again later.\nError: ${error.toString()}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
