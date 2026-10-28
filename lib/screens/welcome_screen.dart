import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../services/app_services.dart";
import "../services/auth_service.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "../theme/hud_shapes.dart";
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

  Future<void> _reconnect() async {
    final bool online = await context.read<AppState>().reconnect();
    if (!mounted) return;
    showCritHitSnack(
      context,
      online
          ? "Conectado! Agora é pra valer: dados salvos no servidor."
          : "Ainda sem resposta do servidor. Confere a internet do aparelho.",
      error: !online,
    );
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
      body: Stack(
        children: [
          // Listras diagonais no topo, como a textura de uma tela de título.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: HudStripes(),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipPath(
                          clipper: ShapeBorderClipper(
                            shape: HudShapes.notch(cut: 30),
                          ),
                          child: Image.asset(
                            "assets/branding/logo.png",
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text(
                                  "🎮",
                                  style: TextStyle(fontSize: 72),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        "CRITHIT",
                        textAlign: TextAlign.center,
                        style: hudLabelStyle(fontSize: 40, letterSpacing: 6),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HudTick(height: 12),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              "Cada jogo merece uma crítica.",
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const _Highlight(
                        number: "01",
                        icon: Icons.star_rounded,
                        iconColor: AppColors.accentGold,
                        text:
                            "Dê de 1 a 5 estrelas pra cada jogo que você jogou",
                      ),
                      const _Highlight(
                        number: "02",
                        icon: Icons.rate_review_rounded,
                        text:
                            "Escreva sua crítica e veja o que a comunidade achou",
                      ),
                      const _Highlight(
                        number: "03",
                        icon: Icons.sports_esports_rounded,
                        text:
                            "Importe sua Steam e sua PSN: horas, troféus e platinas",
                      ),
                      const SizedBox(height: 28),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                        // Caiu para offline porque o servidor não respondeu
                        // (ex.: o celular ainda estava sem rede ao abrir).
                        TextButton.icon(
                          onPressed: state.reconnecting ? null : _reconnect,
                          icon: state.reconnecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text("Tentar conectar de novo"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.number,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  final String number;
  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HudPanel(
        cut: 10,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Text(
              number,
              style: hudNumberStyle(fontSize: 15, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: iconColor ?? AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
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
      child: HudTag(
        icon: online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
        label: online ? "Online · Supabase" : "Offline · dados de exemplo",
        color: online ? AppColors.success : AppColors.textSecondary,
      ),
    );
  }
}
