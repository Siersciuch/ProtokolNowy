import 'package:flutter/material.dart';
import 'package:hh_protokol/services/auth_service.dart';
import 'package:hh_protokol/services/db_service.dart';
import 'package:hh_protokol/ui/login_screen.dart';
import 'package:hh_protokol/ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbService.instance.init();
  runApp(const HHApp());
}

class HHApp extends StatelessWidget {
  const HHApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF7C4DFF),
      scaffoldBackgroundColor: const Color(0xFF06060A),
      cardTheme: const CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HH Protokół',
      theme: theme,
      home: FutureBuilder(
        future: AuthService.instance.hasAnyUser(),
        builder: (context, snap) {
          // Always show login first; app is single-user-per-device in practice.
          return const LoginScreen();
        },
      ),
      routes: {
        HomeScreen.route: (_) => const HomeScreen(),
      },
    );
  }
}
