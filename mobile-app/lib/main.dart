import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const AphtSumenepOneApp());
}

class AphtSumenepOneApp extends StatelessWidget {
  const AphtSumenepOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APHT Sumenep One',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
