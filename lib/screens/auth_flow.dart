import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_auth_service.dart';
import 'biometric_option_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool _isLoadingBiometric = true;
  bool _canBiometric = false;
  bool _showPasswordLogin = false;
  final BiometricAuthService _biometricAuth = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canBio = await _biometricAuth.canLoginWithBiometrics();
      if (mounted) {
        setState(() {
          _canBiometric = canBio;
          _isLoadingBiometric = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      if (mounted) {
        setState(() {
          _canBiometric = false;
          _isLoadingBiometric = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading || _isLoadingBiometric) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isAuthenticated) {
          // If the user gets authenticated, make sure to reset state for the next logout/session check
          if (_showPasswordLogin) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _showPasswordLogin = false;
                });
              }
            });
          }
          return const MainScreen();
        }

        if (_canBiometric && !_showPasswordLogin) {
          return BiometricOptionScreen(
            onPasswordSelected: () {
              setState(() {
                _showPasswordLogin = true;
              });
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
