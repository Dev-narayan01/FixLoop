import 'package:flutter/material.dart';

import 'design/fix_loop_theme.dart';
import 'features/home/home_page.dart';
import 'preview/photo_picker.dart';

export 'features/auth/login_placeholder_page.dart';

void main() {
  runApp(const FixLoopApp());
}

class FixLoopApp extends StatelessWidget {
  const FixLoopApp({this.photoPicker = const DevicePhotoPicker(), super.key});

  /// Override in widget tests; the real picker keeps photos on the device.
  final PreviewPhotoPicker photoPicker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fix Loop',
      debugShowCheckedModeBanner: false,
      theme: fixLoopTheme(Brightness.light),
      darkTheme: fixLoopTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: PreviewHomePage(photoPicker: photoPicker),
    );
  }
}
