import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      debugPrint('Biometrics: canCheck=$canAuthenticateWithBiometrics, deviceSupported=$isDeviceSupported');
      
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || isDeviceSupported;
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } on PlatformException catch (e) {
      debugPrint('Error authenticating: $e');
      return false;
    }
  }
}
