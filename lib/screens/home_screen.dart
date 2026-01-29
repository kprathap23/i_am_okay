import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../services/graphql_service.dart';
import '../widgets/loading_overlay.dart';
import '../models/user_model.dart';
import 'emergency_contact_screen.dart';
import 'daily_reminder_screen.dart';
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

  String get _currentTitle {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'History';
      case 2:
        return 'Emergency Contacts';
      case 3:
        return 'Profile';
      default:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F4ED8),
        title: Text(
          _currentTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
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

  final _storage = const FlutterSecureStorage();
  String? _userName;
  String? _userAlias;
  String? _reminderTime;
  bool _isPaused = false;
  DateTime? _pausedUntil;

  Future<void> _fetchUserData() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        final user = await GraphQLService.getUser(userId);
        if (mounted && user != null) {
          setState(() {
            final firstName = user.name?.firstName ?? '';
            final lastName = user.name?.lastName ?? '';
            _userName = '$firstName $lastName'.trim();
            _userAlias = user.name?.alias;
            
            if (_userName!.isEmpty) {
              _userName = _userAlias;
              _userAlias = null; // Don't show alias if it's the same as name
            } else if (_userAlias == _userName) {
              _userAlias = null;
            }

            if (user.reminderSettings != null) {
              _isPaused = user.reminderSettings!.isPaused ?? false;
              _pausedUntil = user.reminderSettings!.pausedUntil;

              if (user.reminderSettings!.checkInTime != null) {
                final timeParts = user.reminderSettings!.checkInTime!.split(':');
                if (timeParts.length == 2) {
                  final time = TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  );
                  _reminderTime = time.format(context);
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  String _getRelativeTime(DateTime? until) {
    if (until == null) return '';
    final now = DateTime.now();
    final localUntil = until.toLocal();
    final diff = localUntil.difference(now);
    
    if (diff.isNegative) return 'soon';
    
    if (diff.inDays > 1) {
      return '${diff.inDays} days';
    } else if (diff.inDays == 1) {
      return '1 day';
    } else if (diff.inHours > 1) {
      return '${diff.inHours} hours';
    } else if (diff.inHours == 1) {
      return '1 hour';
    } else if (diff.inMinutes > 1) {
      return '${diff.inMinutes} minutes';
    } else {
      return 'less than a minute';
    }
  }

  void _showResumeConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Reminder?'),
        content: const Text('Would you like to start receiving daily reminders again?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReminderStatus(false, null);
            },
            child: const Text('Yes, Resume'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F4ED8),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    LoadingOverlay.show(context);
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        throw Exception("User ID not found");
      }

      // Check permissions and get location
      Map<String, double>? locationData;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            locationData = {
              'lat': position.latitude,
              'lng': position.longitude,
            };
          }
        }
      } catch (e) {
        debugPrint('Location error: $e');
        // Continue without location
      }

      final Map<String, dynamic> checkInPayload = {
        'userId': userId,
        'status': 'OK',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'metadata': {
          'source': 'app',
          'deviceInfo': 'mobile',
        }
      };

      if (locationData != null) {
        checkInPayload['location'] = locationData;
      }

      await GraphQLService.createCheckIn(checkInPayload);

      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful! You are okay!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _fetchUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateReminderStatus(bool isPaused, DateTime? pausedUntil) async {
    LoadingOverlay.show(context);
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) throw Exception("User ID not found");

      await GraphQLService.updateUser(userId, {
        'reminderSettings': {
          'isPaused': isPaused,
          'pausedUntil': pausedUntil?.toUtc().toIso8601String(),
        }
      });

      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() {
          _isPaused = isPaused;
          _pausedUntil = pausedUntil;
        });
        
        String message;
        if (isPaused) {
           final dateStr = pausedUntil?.toString().split(' ')[0] ?? '';
           message = 'Reminder paused until $dateStr';
        } else {
           message = 'Reminder resumed';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
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

  void _showPauseReminderOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(context, '24 hours', duration: const Duration(hours: 24)),
            _buildOption(context, '2 days', duration: const Duration(days: 2)),
            _buildOption(context, '1 week', duration: const Duration(days: 7)),
            _buildOption(context, 'Custom', isCustom: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String text,
      {bool isCustom = false, Duration? duration}) {
    return ListTile(
      title: Text(text),
      onTap: () async {
        Navigator.pop(context); // Close dialog first
        
        DateTime? untilDate;
        
        if (isCustom) {
          // Show date picker or time picker
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            untilDate = picked;
          }
        } else if (duration != null) {
          untilDate = DateTime.now().add(duration);
        }

        if (untilDate != null) {
          _updateReminderStatus(true, untilDate);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_userName != null && _userName!.isNotEmpty) ...[
              Text(
                'Hi, $_userName${_userAlias != null && _userAlias!.isNotEmpty ? ' ($_userAlias)' : ''}',
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _reminderTime != null
                  ? RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF333333),
                        ),
                        children: [
                          const TextSpan(text: "We'll remind you daily at "),
                          TextSpan(
                            text: _reminderTime,
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F4ED8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Text(
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
            // Pulsing Button or Paused Button
            GestureDetector(
              onTap: _isPaused ? _showResumeConfirmDialog : _handleCheckIn,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Continuous Ripples (only if not paused)
                  if (!_isPaused)
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final double offset = index / 3.0;
                          final double value =
                              (_controller.value + offset) % 1.0;
                          return Transform.scale(
                            scale: 1.0 + (value * 0.5), // Expand to 1.5x
                            child: Container(
                              width: 200, // Start at button size
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1F4ED8)
                                    .withValues(alpha: 0.3 * (1 - value)),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  // Main Button
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPaused ? Colors.grey : Colors.white, // Deep Blue or Grey
                      border: _isPaused
                          ? null
                          : Border.all(
                              color: const Color(0xFF1F4ED8),
                              width: 1.0,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isPaused ? Colors.grey : const Color(0xFF1F4ED8))
                              .withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isPaused
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Paused',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'will unpause in',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  _getRelativeTime(_pausedUntil),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/landing_logo.svg',
                                  height: 80,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF1F4ED8),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'I am Okay',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F4ED8),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            // Pause/Resume Reminder Link
            GestureDetector(
              onTap: _isPaused
                  ? () => _updateReminderStatus(false, null)
                  : _showPauseReminderOptions,
              child: Text(
                _isPaused ? 'Resume Reminder' : 'Pause Reminder',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F4ED8), // Link color
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Update Reminder Time Link
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyReminderScreen(),
                  ),
                );
              },
              child: const Text(
                'Update Daily Reminder Time',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F4ED8), // Link color
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
