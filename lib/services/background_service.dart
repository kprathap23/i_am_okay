import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';
import '../gql/mutations/emergency_mutations.dart';

const String emergencySmsTask = "emergencySmsTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case emergencySmsTask:
        try {
          debugPrint("Starting emergency SMS task");
          
          // 1. Get Location
          String locationString = "Unknown";
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            try {
              final position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 10),
                ),
              );
              locationString = "${position.latitude},${position.longitude}";
            } catch (e) {
              debugPrint("Error getting location in background: $e");
              // Fallback or send "Unknown"
            }
          } else {
              debugPrint("Location permission not granted for background task.");
          }

          // 2. Setup GraphQL Client
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'auth_token');
          
          final HttpLink httpLink = HttpLink(
            AppConfig.apiUrl,
          );

          final AuthLink authLink = AuthLink(
            getToken: () async => token != null ? 'Bearer $token' : null,
          );

          final Link link = authLink.concat(httpLink);
          
          final client = GraphQLClient(
            link: link,
            cache: GraphQLCache(),
          );

          // 3. Execute Mutation
          final result = await client.mutate(
            MutationOptions(
              document: gql(sendEmergencySmsMutation),
              variables: {
                'location': locationString,
              },
            ),
          );

          if (result.hasException) {
            debugPrint("Error sending emergency SMS: ${result.exception}");
            return Future.value(false);
          }

          debugPrint("Emergency SMS sent successfully: ${result.data}");
          return Future.value(true);

        } catch (e) {
          debugPrint("Fatal error in emergency SMS task: $e");
          return Future.value(false);
        }
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  Future<void> scheduleEmergencySmsSequence(DateTime startDate) async {
    // Cancel any existing tasks
    await cancelEmergencySms();

    debugPrint("Scheduling emergency SMS sequence for 30 days starting from $startDate");

    for (int i = 0; i < 30; i++) {
      final emergencyTime = startDate.add(Duration(days: i)).add(const Duration(minutes: AppConfig.emergencySmsDelayMinutes));
      final delay = emergencyTime.difference(DateTime.now());

      if (!delay.isNegative) {
        await Workmanager().registerOneOffTask(
          "emergency_sms_$i",
          emergencySmsTask,
          initialDelay: delay,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
          inputData: {},
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
        debugPrint("Scheduled emergency SMS task for day $i with delay: ${delay.inMinutes} minutes");
      }
    }
  }

  Future<void> cancelEmergencySms() async {
    await Workmanager().cancelAll(); 
    // Note: cancelAll cancels everything. If we have other tasks, we should use cancelByTag (if supported) or unique names.
    // For now, assuming this is the only background task. 
    // If we want to be more specific, we'd need to track the ID.
    // However, workmanager cancellation by tag/ID is sometimes tricky. 
    // cancelAll() is safest if this is the only background job.
  }
}
