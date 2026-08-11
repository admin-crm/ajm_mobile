import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> get hasBiometrics async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<void> storeCredentials(String email, String password) async {
    if (kIsWeb) return;
    try {
      await _secureStorage.write(key: 'email', value: email);
      await _secureStorage.write(key: 'password', value: password);
    } catch (e) {
      debugPrint('Error writing credentials to secure storage: $e');
    }
  }

  Future<Map<String, String>?> readStoredCredentials() async {
    if (kIsWeb) return null;
    try {
      final email = await _secureStorage.read(key: 'email');
      final password = await _secureStorage.read(key: 'password');

      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      debugPrint('Error reading credentials from secure storage: $e');
    }
    return null;
  }

  Future<void> clearStoredCredentials() async {
    if (kIsWeb) return;
    try {
      await _secureStorage.delete(key: 'email');
      await _secureStorage.delete(key: 'password');
    } catch (e) {
      debugPrint('Error clearing credentials from secure storage: $e');
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false;
    try {
      final bool supported = await _localAuth.isDeviceSupported();
      final bool hasHardware = await _localAuth.canCheckBiometrics;
      final biometrics = await _localAuth.getAvailableBiometrics();

      if (!supported || !hasHardware || biometrics.isEmpty) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to log in securely',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canLoginWithBiometrics() async {
    if (kIsWeb) return false;
    final hasCreds = await readStoredCredentials();
    final hasBio = await hasBiometrics;
    return hasCreds != null && hasBio;
  }
}
