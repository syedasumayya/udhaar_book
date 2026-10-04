import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'features/home/home_shell.dart';

class UdhaarBookApp extends StatelessWidget {
  const UdhaarBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Udhaar Book',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
