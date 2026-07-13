// Example: place in flutter_app/lib/main.dart
//
// This reads the ENABLE_DEVICE_PREVIEW flag that the Dockerfile passes in via
// --dart-define. Your real mobile/kiosk build never sets this flag, so
// device_preview stays completely out of production builds.

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const bool kEnableDevicePreview =
    bool.fromEnvironment('ENABLE_DEVICE_PREVIEW', defaultValue: false);

void main() {
  runApp(
    DevicePreview(
      enabled: kEnableDevicePreview && !kReleaseMode ? true : kEnableDevicePreview,
      builder: (context) => const VmsApp(),
    ),
  );
}

class VmsApp extends StatelessWidget {
  const VmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BCGHQ VMS',
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const Placeholder(), // swap for your actual home screen
    );
  }
}
