import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'hotline_service.dart';
import 'welcome_screen.dart';

void main() {
  // Download the hotline list early, so it is ready if the connection drops.
  HotlineService.load();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const KalinawApp(),
    ),
  );
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
      home: const WelcomeScreen(),
    );
  }
}