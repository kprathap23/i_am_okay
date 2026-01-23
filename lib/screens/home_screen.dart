import 'package:flutter/material.dart';
import 'emergency_contact_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const HistoryScreen(),
    const EmergencyContactScreen(isOnboarding: false),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1F4ED8),
        unselectedItemColor: const Color(0xFF333333),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_phone),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showPauseReminderOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(context, '24 hours'),
            _buildOption(context, '2 days'),
            _buildOption(context, '1 week'),
            _buildOption(context, 'Custom', isCustom: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String text,
      {bool isCustom = false}) {
    return ListTile(
      title: Text(text),
      onTap: () async {
        Navigator.pop(context); // Close dialog first
        if (isCustom) {
          // Show date picker or time picker
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Reminder paused until ${picked.toString().split(' ')[0]}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reminder paused for $text')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F4ED8),
        title: const Text(
          'IAmOkay',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // Don't show back button on Home tab
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'How are you feeling?',
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'We are here to support you. Let us know you are okay.',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            // Pulsing Button
            GestureDetector(
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checking in... You are okay!')),
                  );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Ripple
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_controller.value * 0.5),
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1F4ED8)
                                .withValues(alpha: 0.3 * (1 - _controller.value)),
                          ),
                        ),
                      );
                    },
                  ),
                  // Inner Ripple
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_controller.value * 0.3),
                        child: Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1F4ED8)
                                .withValues(alpha: 0.5 * (1 - _controller.value)),
                          ),
                        ),
                      );
                    },
                  ),
                  // Main Button
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1F4ED8), // Deep Blue
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'IAmOkay',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            // Pause Reminder Link
            GestureDetector(
              onTap: _showPauseReminderOptions,
              child: const Text(
                'Pause Reminder',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F4ED8), // Link color
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
