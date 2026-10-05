import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "screens/auth_gate.dart";
import "services/app_services.dart";
import "state/app_state.dart";
import "theme/app_theme.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Decide entre Supabase (online) e dados mockados (offline) antes de
  // desenhar a primeira tela.
  final AppServices services = await AppServices.create();
  runApp(CritHitApp(services: services));
}

/// Widget raiz do CritHit.
class CritHitApp extends StatelessWidget {
  const CritHitApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(services)..init(),
      child: MaterialApp(
        title: "CritHit",
        debugShowCheckedModeBanner: false,
        theme: buildCritHitTheme(),
        home: const AuthGate(),
      ),
    );
  }
}
