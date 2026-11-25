import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/google.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
    );
  }
}
