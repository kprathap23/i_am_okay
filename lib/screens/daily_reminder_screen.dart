import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_overlay.dart';
import '../services/graphql_service.dart';
import '../services/notification_service.dart';
import 'permission_screen.dart';

class DailyReminderScreen extends StatefulWidget {
  const DailyReminderScreen({super.key});

  @override
  State<DailyReminderScreen> createState() => _DailyReminderScreenState();
}

class _DailyReminderScreenState extends State<DailyReminderScreen> {
  final _storage = const FlutterSecureStorage();
  TimeOfDay? _selectedTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentReminder();
  }

  Future<void> _fetchCurrentReminder() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        final user = await GraphQLService.getUser(userId);
        if (mounted && user?.reminderSettings?.checkInTime != null) {
          final timeParts = user!.reminderSettings!.checkInTime!.split(':');
          if (timeParts.length == 2) {
            setState(() {
              _selectedTime = TimeOfDay(
                hour: int.parse(timeParts[0]),
                minute: int.parse(timeParts[1]),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching reminder settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSetReminder() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    LoadingOverlay.show(context);

    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        throw Exception('User not found');
      }

      // Format time as HH:mm (24-hour format)
      final formattedTime =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      await GraphQLService.updateUser(userId, {
        'reminderSettings': {
          'checkInTime': formattedTime,
          'isPaused': false,
        },
      });

      // Schedule local notification
      await NotificationService().requestPermissions();
      await NotificationService().scheduleDailyNotification(_selectedTime!);

      if (mounted) {
        LoadingOverlay.hide(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PermissionScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("hello error$e");
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1F4ED8), // Deep Blue
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: const Text(
          'Daily Reminder',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000000)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              const Text(
                'Set a time for your daily safety check-in.',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select Time',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w600,
                          color: _selectedTime != null
                              ? const Color(0xFF1F4ED8)
                              : const Color(0xFF999999),
                        ),
                      ),
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF1F4ED8),
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Set Reminder',
                onPressed: _handleSetReminder,
              ),
                    const SizedBox(height: 24),
                  ],
                ),
            ),
      ),
    );
  }
}
