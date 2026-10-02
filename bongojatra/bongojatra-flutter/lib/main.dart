import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BongoJatraApp());
}

class BongoJatraApp extends StatelessWidget {
  const BongoJatraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BongoJatra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashScreen(),
    );
  }
}
