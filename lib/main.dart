import "package:flutter/material.dart";

import "screens/home_screen.dart";
import "theme/app_theme.dart";

void main() {
  runApp(const CritHitApp());
}

/// Widget raiz do CritHit.
class CritHitApp extends StatelessWidget {
  const CritHitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CritHit",
      debugShowCheckedModeBanner: false,
      theme: buildCritHitTheme(),
      home: const HomeScreen(),
    );
  }
}
