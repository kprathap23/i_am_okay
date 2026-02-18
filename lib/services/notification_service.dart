import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import 'background_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone().then((tz) => tz.identifier);
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Local timezone successfully set to: $timeZoneName');
    } catch (e) {
      debugPrint('Error setting local timezone: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // Handle notification tap
        debugPrint('Notification tapped: ${notificationResponse.payload}');
        
      },
    );
  }

  Future<bool> requestPermissions() async {
    bool? iosGranted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    bool? androidGranted = await androidImplementation?.requestNotificationsPermission();
    if (androidImplementation != null) {
        final canSchedule = await androidImplementation.canScheduleExactNotifications();
      debugPrint('Can schedule exact alarms: $canSchedule');
      
      if (canSchedule == false) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
    
    final granted = (iosGranted ?? false) || (androidGranted ?? false);
    debugPrint('Permissions granted: $granted (iOS: $iosGranted, Android: $androidGranted)');
    return granted;
  }

  Future<void> scheduleDailyNotification(TimeOfDay time) async {
    // Always cancel existing notifications to ensure we don't have duplicates or stale times
    await cancelAllNotifications();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleDailyNotificationFromDate(scheduledDate);
  }

  Future<void> scheduleDailyNotificationFromDate(tz.TZDateTime startDate) async {
    // Always cancel existing notifications to ensure we don't have duplicates or stale times
    await cancelAllNotifications();

    // Schedule main notifications
    await _scheduleNotifications(startDate, 0, 'daily_checkin', 'Daily Check-in', 'Time to check in! Are you okay?');
    
    // Schedule follow-up reminders
    final reminderDate = startDate.add(const Duration(minutes: AppConfig.followUpReminderDelayMinutes));
    await _scheduleNotifications(reminderDate, 100, 'checkin_reminder', 'Check-in Reminder', 'You haven\'t checked in yet. Is everything okay?');

    // Schedule Emergency SMS Task Sequence (starting from the first scheduled date)
    // The background service will handle the 15-day loop logic.
    await BackgroundService().scheduleEmergencySmsSequence(startDate);
  }

  Future<void> _scheduleNotifications(tz.TZDateTime startDate, int startId, String type, String title, String body) async {
    try {
      for (int i = 0; i < 15; i++) {
        final tz.TZDateTime notificationDate = startDate.add(Duration(days: i));

        final payload = jsonEncode({
          'type': type,
          'scheduledDate': notificationDate.toIso8601String(),
        });

        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
              id: startId + i,
              title: title,
              body: body,
              scheduledDate: notificationDate,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'daily_checkin_channel_v3',
                  'Daily Check-in',
                  channelDescription: 'Reminds you to check in daily',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: payload);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    } catch (e) {
      debugPrint('ERROR scheduling notification ($type): $e');
    }
  }

  Future<void> completeDailyCheckIn(TimeOfDay checkInTime) async {
    // 1. Cancel all reminder notifications (100-129)
    // We don't cancel main notifications (0-29) because we want them to keep firing daily.
    for (int i = 0; i < 15; i++) {
      await flutterLocalNotificationsPlugin.cancel(id: 100 + i);
    }
    // Cancel any pending emergency SMS task since user checked in
    await BackgroundService().cancelEmergencySms();
    
    debugPrint('Cancelled check-in reminders and emergency task');

    // 2. Reschedule reminders starting from TOMORROW
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime todayCheckIn = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      checkInTime.hour,
      checkInTime.minute,
    );
    
    // Start from tomorrow
    final tz.TZDateTime tomorrowCheckIn = todayCheckIn.add(const Duration(days: 1));
    final reminderDate = tomorrowCheckIn.add(const Duration(minutes: AppConfig.followUpReminderDelayMinutes));
    
    await _scheduleNotifications(reminderDate, 100, 'checkin_reminder', 'Check-in Reminder', 'You haven\'t checked in yet. Is everything okay?');

    // Schedule Emergency SMS Sequence for tomorrow
    // We start the sequence from tomorrow's check-in time.
    await BackgroundService().scheduleEmergencySmsSequence(tomorrowCheckIn);
  }


  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    await BackgroundService().cancelEmergencySms();
  }
}
