import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "main_shell.dart";
import "welcome_screen.dart";

/// Decide a primeira tela: carregando → boas-vindas (deslogado) → app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    if (state.initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: state.isSignedIn
          ? const MainShell(key: ValueKey<String>("app"))
          : const WelcomeScreen(key: ValueKey<String>("welcome")),
    );
  }
}
