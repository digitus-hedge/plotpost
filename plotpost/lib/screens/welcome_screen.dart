import 'package:flutter/material.dart';

import 'auth_form_screen.dart';
import 'browse_screen.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/google_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _googleLoading = false;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _googleLoading = true);
    final result = await ApiService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (result['success'] == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BrowseScreen()),
        (_) => false,
      );
      return;
    }
    if (result['cancelled'] == true) return;
    _showInfo(context, result['message']?.toString() ?? 'Google sign-in failed.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/plotpost_logo_light.png'
                      : 'assets/plotpost_logo_dark.png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
                  const SizedBox(height: 9),
                  Text(
                    'Discover. Connect. Share.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 38),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 49,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          _open(context, const AuthFormScreen(isSignUp: false)),
                      child: Text(
                        'Log In',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _googleLoading ? null : _continueWithGoogle,
                      icon: _googleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const GoogleLogo(size: 20),
                      label: Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () =>
                          _open(context, const AuthFormScreen(isSignUp: true)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.secondary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Create New Account',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const BrowseScreen(isGuest: true),
                      ),
                    ),
                    child: Text(
                      'Explore without logging in',
                      style: TextStyle(
                        color: plotPostTextAccent(
                          context,
                          Theme.of(context).colorScheme.primary,
                        ),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By continuing, you agree to our Terms and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
