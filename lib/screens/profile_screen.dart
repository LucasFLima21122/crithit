import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/app_user.dart";
import "../models/game.dart";
import "../models/review.dart";
import "../models/steam.dart";
import "../services/app_services.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../utils/formatters.dart";
import "../widgets/common.dart";
import "../widgets/review_tile.dart";
import "game_detail_screen.dart";
import "library_screen.dart";
import "main_shell.dart";

/// Aba "Perfil": quem é o usuário, estatísticas, conta Steam e o histórico
/// de todas as críticas que ele escreveu.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, AppState state) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sair da conta?"),
        content: Text(
          state.user?.isGuest ?? false
              ? "Como convidado, suas reviews ficam salvas, mas você não vai conseguir entrar de novo nesta mesma conta."
              : "Você pode entrar de novo quando quiser.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text("Sair"),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppUser? user = state.user;
    if (user == null) return const SizedBox.shrink();

    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Review> mine = state.myReviews;
    final SteamLibrary? library = state.library;
    final double myAverage = mine.isEmpty
        ? 0
        : mine.fold<int>(0, (sum, r) => sum + r.rating) / mine.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        actions: [
          IconButton(
            tooltip: "Sair",
            onPressed: () => _confirmSignOut(context, state),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ContentWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      UserAvatar(
                        initials: user.initials,
                        imageUrl: library?.profile.avatarUrl,
                        size: 68,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.isGuest
                                  ? "Conta de convidado"
                                  : (user.email ?? ""),
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  state.mode == BackendMode.online
                                      ? Icons.cloud_done_rounded
                                      : Icons.cloud_off_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    state.mode == BackendMode.online
                                        ? "Sincronizado com o Supabase"
                                        : "Modo offline (dados de exemplo)",
                                    style: textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: "${mine.length}",
                          label: "Críticas",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          value: mine.isEmpty ? "—" : formatAverage(myAverage),
                          label: "Nota média",
                          icon: Icons.star_rounded,
                          iconColor: AppColors.accentGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          value: library == null
                              ? "—"
                              : "${library.games.length}",
                          label: "Na Steam",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          value: library == null
                              ? "—"
                              : "${library.platinumCount}",
                          label: "Platinados",
                          icon: Icons.emoji_events_rounded,
                          iconColor: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SteamAccountCard(state: state),
                  if (mine.isNotEmpty) ...[
                    const SectionHeader(
                      title: "Suas notas",
                      padding: EdgeInsets.fromLTRB(0, 24, 0, 10),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: RatingDistribution(
                        ratings: mine.map((r) => r.rating).toList(),
                      ),
                    ),
                  ],
                  const SectionHeader(
                    title: "Suas críticas",
                    padding: EdgeInsets.fromLTRB(0, 24, 0, 10),
                  ),
                  if (mine.isEmpty)
                    EmptyState(
                      emoji: "✍️",
                      title: "Nenhuma crítica ainda",
                      message:
                          "Escolhe um jogo que você zerou (ou largou) e conta o que achou.",
                      actionLabel: "Buscar um jogo",
                      onAction: () =>
                          MainShell.goToTab(context, MainShell.searchTab),
                    )
                  else
                    for (final Review review in mine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ReviewTile(
                          review: review,
                          showGameTitle: true,
                          onTap: () {
                            final Game? game = state.gameById(review.gameId);
                            if (game != null) openGame(context, game);
                          },
                        ),
                      ),
                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context, state),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text("Sair da conta"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      "CritHit · Cada jogo merece uma crítica.",
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SteamAccountCard extends StatelessWidget {
  const _SteamAccountCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final SteamLibrary? library = state.library;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_esports_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Steam", style: textTheme.titleMedium),
                Text(
                  state.loadingSteam
                      ? "Importando biblioteca..."
                      : library == null
                      ? "Não conectada"
                      : "${library.profile.personaName} · ${formatHoursTotal(library.totalPlaytimeMinutes)} h jogadas",
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (library == null)
            TextButton(
              onPressed: state.loadingSteam
                  ? null
                  : () => openSteamConnect(context),
              child: const Text("Conectar"),
            )
          else
            TextButton(
              onPressed: () => MainShell.goToTab(context, MainShell.libraryTab),
              child: const Text("Ver biblioteca"),
            ),
        ],
      ),
    );
  }
}
