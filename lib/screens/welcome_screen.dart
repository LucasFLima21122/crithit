import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../services/app_services.dart";
import "../services/auth_service.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../widgets/common.dart";
import "auth_screen.dart";

/// Primeira tela para quem não está logado: marca, proposta de valor e as
/// três portas de entrada (entrar, criar conta, explorar como convidado).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loadingGuest = false;

  Future<void> _enterAsGuest() async {
    setState(() => _loadingGuest = true);
    try {
      await context.read<AppState>().signInAsGuest();
    } on AuthFailure catch (error) {
      if (mounted) showCritHitSnack(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _loadingGuest = false);
    }
  }

  void _openAuth(bool signUp) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(startWithSignUp: signUp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppState state = context.watch<AppState>();
    final String? notice = state.services.notice;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        "assets/branding/logo.png",
                        width: 132,
                        height: 132,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text("🎮", style: TextStyle(fontSize: 72)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "CritHit",
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Cada jogo merece uma crítica.",
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _Highlight(
                    icon: Icons.star_rounded,
                    iconColor: AppColors.accentGold,
                    text: "Dê de 1 a 5 estrelas pra cada jogo que você jogou",
                  ),
                  const _Highlight(
                    icon: Icons.rate_review_rounded,
                    text: "Escreva sua crítica e veja o que a comunidade achou",
                  ),
                  const _Highlight(
                    icon: Icons.sports_esports_rounded,
                    text:
                        "Importe sua biblioteca Steam: horas, conquistas e platinas",
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _openAuth(false),
                    child: const Text("Entrar"),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _openAuth(true),
                    child: const Text("Criar conta"),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadingGuest ? null : _enterAsGuest,
                    child: _loadingGuest
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Explorar como convidado"),
                  ),
                  const SizedBox(height: 16),
                  _ModeChip(mode: state.mode),
                  if (notice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      notice,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.text, this.iconColor});

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Indica se o app está conectado ao Supabase ou rodando com dados mockados.
class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode});

  final BackendMode mode;

  @override
  Widget build(BuildContext context) {
    final bool online = mode == BackendMode.online;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              online
                  ? "Online · dados salvos no Supabase"
                  : "Modo offline · dados de exemplo",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
