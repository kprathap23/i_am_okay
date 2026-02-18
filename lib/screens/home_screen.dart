import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/graphql_service.dart';
import '../services/notification_service.dart';
import '../widgets/loading_overlay.dart';
import 'emergency_contact_screen.dart';
import 'daily_reminder_screen.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../widgets/bottom_nav_item.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _userRole;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    const storage = FlutterSecureStorage();
    _userRole = await storage.read(key: 'user_role');
    _userId = await storage.read(key: 'user_id');
    setState(() {});
  }

  List<Widget> get _screens {
    if (_userRole == 'contact') {
      return [
        HistoryScreen(contactId: _userId),
        const SettingsScreen(),
      ];
    }
    return [
      const HomeContent(),
      const HistoryScreen(),
      const EmergencyContactScreen(isOnboarding: false),
      const SettingsScreen(),
    ];
  }

  String get _currentTitle {
    if (_userRole == 'contact') {
      switch (_currentIndex) {
        case 0:
          return 'History';
        case 1:
          return 'Settings';
        default:
          return 'History';
      }
    }
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'History';
      case 2:
        return 'Emergency Contacts';
      case 3:
        return 'Settings';
      default:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) {

    final List<BottomNavItem> navItems = _userRole == 'contact'
        ? [
            BottomNavItem(icon: Icons.history, label: 'History'),
            BottomNavItem(icon: Icons.settings, label: 'Settings'),
          ]
        : [
            BottomNavItem(icon: Icons.home, label: 'Home'),
            BottomNavItem(icon: Icons.history, label: 'History'),
            BottomNavItem(icon: Icons.contact_phone, label: 'Contacts'),
            BottomNavItem(icon: Icons.settings, label: 'Settings'),
          ];

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
      bottomNavigationBar: CustomBottomNavbar(
        items: navItems,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
  TimeOfDay? _checkInTimeOfDay;
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
                  _checkInTimeOfDay = time;
                  _reminderTime = time.format(context);
                }
              }
            }
          });

          // Handle notifications outside setState
          if (user.reminderSettings != null && user.reminderSettings!.checkInTime != null) {
             final timeParts = user.reminderSettings!.checkInTime!.split(':');
             if (timeParts.length == 2) {
               final time = TimeOfDay(
                 hour: int.parse(timeParts[0]),
                 minute: int.parse(timeParts[1]),
               );
               final isPaused = user.reminderSettings!.isPaused ?? false;
               final pausedUntil = user.reminderSettings!.pausedUntil;
               

               // Schedule if not paused OR if the pause duration has expired
               // ignoring pausedUntil if isPaused is false
               if (!isPaused || (pausedUntil != null && DateTime.now().isAfter(pausedUntil))) {
                  await NotificationService().scheduleDailyNotification(time);
               } else {
                  await NotificationService().cancelAllNotifications();
               }
             }
          }
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
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
            ),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReminderStatus(false, null);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F4ED8),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes, Resume'),
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
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
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

      // Cancel the check-in reminder notification since user has checked in
      if (_checkInTimeOfDay != null) {
        await NotificationService().completeDailyCheckIn(_checkInTimeOfDay!);
      } else if (_reminderTime != null) {
        // Fallback for parsing if _checkInTimeOfDay is null for some reason
        try {
          final parts = _reminderTime!.split(':');
          if (parts.length == 2) {
            // This might fail if format is 12h, so we try-catch it
             final time = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
            await NotificationService().completeDailyCheckIn(time);
          }
        } catch (e) {
          debugPrint('Error parsing time from string: $e');
        }
      }

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
        debugPrint(e.toString());
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

        // Handle notification rescheduling
        if (isPaused) {
          if (pausedUntil != null && _checkInTimeOfDay != null) {
            final localPausedUntil = pausedUntil.toLocal();
            var scheduledDate = tz.TZDateTime(
              tz.local,
              localPausedUntil.year,
              localPausedUntil.month,
              localPausedUntil.day,
              _checkInTimeOfDay!.hour,
              _checkInTimeOfDay!.minute,
            );

            // if pausedUntil hour and minute (converted to local timezone) is more than the check-in time then schedule it to next day.
            if (localPausedUntil.hour > _checkInTimeOfDay!.hour ||
                (localPausedUntil.hour == _checkInTimeOfDay!.hour &&
                    localPausedUntil.minute > _checkInTimeOfDay!.minute)) {
              scheduledDate = scheduledDate.add(const Duration(days: 1));
            }
            NotificationService().scheduleDailyNotificationFromDate(scheduledDate);
          } else {
            // If we can't reschedule, at least cancel everything.
            NotificationService().cancelAllNotifications();
          }
        } else {
          // Resuming
          if (_checkInTimeOfDay != null) {
            NotificationService().scheduleDailyNotification(_checkInTimeOfDay!);
          }
        }

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
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
            ),
            child: const Text('Cancel'),
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

  Widget _buildPauseResumeButton() {
    if (_isPaused) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_arrow, color: Color(0xFF666666)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showResumeConfirmDialog,
            child: const Text(
              'Resume Reminder',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F4ED8), // Link color
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }
    return TextButton.icon(
      onPressed: _showPauseReminderOptions,
      icon: const Icon(Icons.pause, color: Color(0xFF666666)),
      label: const Text(
        'Pause Reminder',
        style: TextStyle(color: Color(0xFF666666), fontSize: 16),
      ),
    );
  }

  Widget _buildMainActionButton() {
    return GestureDetector(
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
                  final double value = (_controller.value + offset) % 1.0;
                  return Transform.scale(
                    scale: 1.0 + (value * 0.5), // Expand to 1.5x
                    child: Container(
                      width: 200, // Start at button size
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1F4ED8).withAlpha((255 * 0.3 * (1 - value)).toInt()),
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
              color: _isPaused ? Colors.grey[400] : Colors.white,
              border: _isPaused
                  ? null
                  : Border.all(
                      color: const Color(0xFF1F4ED8).withAlpha((255 * 0.5).toInt()),
                      width: 1.0,
                    ),
              boxShadow: [
                BoxShadow(
                  color: (_isPaused ? Colors.grey : const Color(0xFF1F4ED8))
                      .withAlpha((255 * 0.2).toInt()),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: _isPaused
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pause, color: Colors.white, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'Paused',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Resumes in ${_getRelativeTime(_pausedUntil)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/landing_logo.svg',
                          height: 70,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF1F4ED8),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'I am Okay',
                          style: TextStyle(
                            fontSize: 22.0,
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
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userName != null && _userName!.isNotEmpty)
            Text(
              'Hi, $_userName${_userAlias != null && _userAlias!.isNotEmpty ? ' ($_userAlias)' : ''}',
              style: const TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 24),
          if (_reminderTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active, color: Color(0xFF1F4ED8), size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF333333),
                        ),
                        children: [
                          const TextSpan(text: "Daily check-in at "),
                          TextSpan(
                            text: _reminderTime,
                            style: const TextStyle(
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
            )
          else
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DailyReminderScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F4ED8)
                    .withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                        color: const Color(0xFF1F4ED8)
                            .withAlpha((255 * 0.3).toInt())),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_alert, color: Color(0xFF1F4ED8), size: 20),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        'Set a Daily Reminder',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pulsing Button or Paused Button
                    _buildMainActionButton(),
                    const SizedBox(height: 60),
                    // Pause/Resume button
                    _buildPauseResumeButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
