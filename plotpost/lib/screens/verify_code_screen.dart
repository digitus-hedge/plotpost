import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/auth_field.dart';
import 'browse_screen.dart';

enum CodePurpose { verifyEmail, resetPassword }

/// Enter the 6-digit code from the email: to verify the email address after
/// registering, or to set a new password after "Forgot password".
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.purpose,
    required this.email,
    this.continueToApp = true,
  });

  final CodePurpose purpose;
  final String email;

  /// After success (or "Skip for now"), open the app instead of going back.
  final bool continueToApp;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;

  bool get _isReset => widget.purpose == CodePurpose.resetPassword;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _finish() {
    if (widget.continueToApp) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BrowseScreen()),
        (_) => false,
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final result = _isReset
        ? await ApiService.resetPassword(
            email: widget.email,
            code: _codeController.text,
            newPassword: _passwordController.text,
          )
        : await ApiService.verifyEmail(_codeController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    final success = result['success'] == true;
    _showMessage(
      result['message']?.toString() ??
          (success ? 'Done.' : 'That code did not work.'),
      success: success,
    );
    if (success) _finish();
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    final result = _isReset
        ? await ApiService.forgotPassword(widget.email)
        : await ApiService.resendVerification();
    if (!mounted) return;
    setState(() => _isResending = false);
    _showMessage(
      result['message']?.toString() ?? 'Code sent.',
      success: result['success'] == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 92,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Image.asset(
            theme.brightness == Brightness.dark
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
                _isReset ? 'Set a new password' : 'Verify your email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code we sent to ${widget.email}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              AuthField(
                controller: _codeController,
                hint: '6-digit code',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || !RegExp(r'^\d{6}$').hasMatch(val.trim())) {
                    return 'Please enter the 6-digit code';
                  }
                  return null;
                },
              ),
              if (_isReset) ...[
                const SizedBox(height: 12),
                AuthField(
                  controller: _passwordController,
                  hint: 'New password',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: validateNewPassword,
                ),
                const SizedBox(height: 12),
                AuthField(
                  controller: _confirmController,
                  hint: 'Confirm new password',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: (val) => val != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 49,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
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
                      : Text(_isReset ? 'Reset password' : 'Verify email'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isResending ? null : _resend,
                child: Text(_isResending ? 'Sending…' : 'Send a new code'),
              ),
              if (!_isReset)
                TextButton(
                  onPressed: _isLoading ? null : _finish,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
