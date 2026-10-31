import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'admin_screen.dart';
import 'auth_service.dart';
import 'counselor_screen.dart';
import 'hotline_service.dart';
import 'phq9_screen.dart';
import 'phrase_service.dart';
import 'welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load what was saved last time, so emergency help and the warning scan
  // work even with no connection.
  await Future.wait([
    HotlineService.restore(),
    PhraseService.restore(),
  ]);

  // Then refresh both lists from the server in the background.
  HotlineService.load();
  PhraseService.refresh();

  // Pick up a saved login, but never wait more than a few seconds for it.
  await AuthService.restore().timeout(
    const Duration(seconds: 6),
    onTimeout: () {},
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const KalinawApp(),
    ),
  );
}

Widget _startScreen() {
  if (!AuthService.loggedIn) return const WelcomeScreen();
  if (AuthService.isAdmin) return const AdminScreen();
  if (AuthService.isCounselor) return const CounselorScreen();
  return const Phq9Screen();
}

class KalinawApp extends StatelessWidget {
  const KalinawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalinaw',
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F6B6B),
        ),
      ),
      home: _startScreen(),
    );
  }
}