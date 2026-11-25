import 'package:flutter/material.dart';

import 'browse_screen.dart';
import 'verify_code_screen.dart';
import '../services/api_service.dart';
import '../widgets/auth_field.dart';

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({
    super.key,
    required this.isSignUp,
    this.forgotPassword = false,
  });

  final bool isSignUp;
  final bool forgotPassword;

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim().toLowerCase();
    final result = await ApiService.forgotPassword(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Code sent.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            purpose: CodePurpose.resetPassword,
            email: email,
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.forgotPassword) {
      await _sendResetCode();
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> result;
    if (widget.isSignUp) {
      result = await ApiService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      result = await ApiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    final bool success = result['success'] == true;
    final String message =
        result['message']?.toString() ??
        (success ? 'Success!' : 'Authentication failed.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (!success) return;

    // New accounts get a 6-digit code by email; they can verify now or skip.
    if (widget.isSignUp && result['verificationEmailSent'] == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            purpose: CodePurpose.verifyEmail,
            email: _emailController.text.trim().toLowerCase(),
          ),
        ),
        (_) => false,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BrowseScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.forgotPassword
        ? 'Reset password'
        : (widget.isSignUp ? 'Create account' : 'Welcome back');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 92,
        titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/plotpost_logo_light.png'
                  : 'assets/plotpost_logo_dark.png',
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.forgotPassword
                    ? "Enter your email and we'll send you a 6-digit code."
                    : (widget.isSignUp
                          ? 'Join the PlotPost community.'
                          : 'Log in to your PlotPost account.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              if (widget.isSignUp) ...[
                AuthField(
                  controller: _nameController,
                  hint: 'Full name',
                  icon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              AuthField(
                controller: _emailController,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!val.contains('@') || !val.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              if (!widget.forgotPassword) ...[
                const SizedBox(height: 12),
                AuthField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: (val) {
                    if (widget.isSignUp) return validateNewPassword(val);
                    if (val == null || val.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                if (!widget.isSignUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AuthFormScreen(
                                    isSignUp: false,
                                    forgotPassword: true,
                                  ),
                                ),
                              ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 49,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.forgotPassword
                              ? 'Send reset code'
                              : (widget.isSignUp ? 'Create Account' : 'Log In'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
