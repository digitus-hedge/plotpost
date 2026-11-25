import 'package:flutter/material.dart';

/// Same rule the server enforces for new passwords.
String? validateNewPassword(String? val) {
  if (val == null || val.isEmpty) return 'Please enter a password';
  if (val.length < 8) return 'Password must be at least 8 characters';
  if (val.length > 72) return 'Password must be at most 72 characters';
  if (!RegExp(r'[A-Za-z]').hasMatch(val)) {
    return 'Password must include at least one letter';
  }
  if (!RegExp(r'[0-9]').hasMatch(val)) {
    return 'Password must include at least one number';
  }
  return null;
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.validator,
  });

  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            size: 19,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 1.2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 1.4,
            ),
          ),
        ),
      );
}
