import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/morphly_theme.dart';

class MorphlyApp extends StatelessWidget {
  const MorphlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morphly',
      debugShowCheckedModeBanner: false,
      theme: MorphlyTheme.dark,
      home: const SplashScreen(),
    );
  }
}
