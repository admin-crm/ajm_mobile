import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_auth_service.dart';

class BiometricOptionScreen extends StatefulWidget {
  final VoidCallback onPasswordSelected;
  const BiometricOptionScreen({super.key, required this.onPasswordSelected});

  @override
  State<BiometricOptionScreen> createState() => _BiometricOptionScreenState();
}

class _BiometricOptionScreenState extends State<BiometricOptionScreen> {
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  bool _isLoading = false;

  Future<void> _loginWithBiometrics() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final isAuthenticated = await _biometricAuth.authenticateWithBiometrics();
      if (!mounted) return;

      if (isAuthenticated) {
        final creds = await _biometricAuth.readStoredCredentials();
        if (!mounted) return;

        if (creds != null) {
          final success = await auth.login(creds['email']!, creds['password']!);
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Server authentication failed.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credentials not found. Please log in with password.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication failed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Biometric Login',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock your HRM portal securely',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _loginWithBiometrics,
                      icon: const Icon(Icons.face_retouching_natural_rounded),
                      label: const Text('Use Face ID / Touch ID'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: widget.onPasswordSelected,
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: const Text('Use Email & Password'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
