import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/app_user.dart";
import "../models/game.dart";
import "../models/library.dart";
import "../models/review.dart";
import "../services/app_services.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "../theme/hud_shapes.dart";
import "../utils/formatters.dart";
import "../utils/player_level.dart";
import "../widgets/common.dart";
import "../widgets/platform_style.dart";
import "../widgets/review_tile.dart";
import "game_detail_screen.dart";
import "library_screen.dart";
import "main_shell.dart";

/// Aba "Perfil": a ficha do jogador (nível de crítico e XP), estatísticas,
/// contas conectadas e o histórico de todas as críticas que ele escreveu.
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
    final double myAverage = mine.isEmpty
        ? 0
        : mine.fold<int>(0, (sum, r) => sum + r.rating) / mine.length;
    final List<OwnedGame> owned = state.ownedGames;
    final int platinums = owned.where((g) => g.isPlatinum).length;

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
                  const SizedBox(height: 4),
                  _PlayerCard(user: user, level: state.playerLevel),
                  const SizedBox(height: 12),
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
                          value: state.hasAnyLibrary ? "${owned.length}" : "—",
                          label: "Jogos",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          value: state.hasAnyLibrary ? "$platinums" : "—",
                          label: "Platinados",
                          icon: Icons.emoji_events_rounded,
                          iconColor: AppColors.platinum,
                        ),
                      ),
                    ],
                  ),
                  const SectionHeader(
                    title: "Contas conectadas",
                    padding: EdgeInsets.fromLTRB(0, 28, 0, 12),
                  ),
                  for (final GamePlatform platform in GamePlatform.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AccountRow(state: state, platform: platform),
                    ),
                  if (mine.isNotEmpty) ...[
                    const SectionHeader(
                      title: "Suas notas",
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 12),
                    ),
                    HudPanel(
                      child: RatingDistribution(
                        ratings: mine.map((r) => r.rating).toList(),
                      ),
                    ),
                  ],
                  const SectionHeader(
                    title: "Suas críticas",
                    padding: EdgeInsets.fromLTRB(0, 28, 0, 12),
                  ),
                  if (mine.isEmpty)
                    EmptyState(
                      emoji: "✍️",
                      title: "Nenhuma crítica ainda",
                      message:
                          "Escolhe um jogo que você zerou (ou largou) e conta o que achou. Cada crítica vale XP.",
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
                      state.mode == BackendMode.online
                          ? "Sincronizado com o Supabase"
                          : "Modo offline (dados de exemplo)",
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

/// A ficha do jogador: avatar, nome, nível, título e a barra de XP.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.user, required this.level});

  final AppUser user;
  final PlayerLevel level;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppState state = context.watch<AppState>();
    final String? avatar =
        state.library?.avatarUrl ?? state.psnLibrary?.avatarUrl;

    return Material(
      color: AppColors.surface,
      shape: HudShapes.outlined(
        cut: 22,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: HudStripes()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      initials: user.initials,
                      imageUrl: avatar,
                      size: 72,
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
                          const SizedBox(height: 10),
                          HudTag(
                            label: level.rank,
                            color: Colors.white,
                            background: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          "LV",
                          style: hudLabelStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          "${level.level}",
                          style: hudNumberStyle(fontSize: 44),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      "XP",
                      style: hudLabelStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${formatThousands(level.xp)} / ${formatThousands(level.nextLevelXp)}",
                      style: hudNumberStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    Tooltip(
                      message:
                          "Crítica com texto: ${PlayerLevel.xpPerReview} XP · só a nota: ${PlayerLevel.xpPerRating} XP · platina: ${PlayerLevel.xpPerPlatinum} XP · cada hora jogada: 1 XP",
                      triggerMode: TooltipTriggerMode.tap,
                      child: Row(
                        children: [
                          Text(
                            "faltam ${formatThousands(level.xpToNext)} XP",
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedBar(value: level.progress, segments: 20, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma conta de plataforma: conectada (com resumo) ou o convite a conectar.
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.state, required this.platform});

  final AppState state;
  final GamePlatform platform;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final GameLibrary? library = state.libraryFor(platform);
    final bool loading = platform == GamePlatform.steam
        ? state.loadingSteam
        : state.loadingPsn;
    final String summary = loading
        ? "Importando biblioteca..."
        : library == null
        ? "Não conectada"
        : "${library.accountName} · ${library.games.length} jogos · ${library.platinumCount} platinas";

    return HudPanel(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Icon(platform.icon, color: platform.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(platform.label, style: textTheme.titleMedium),
                Text(
                  summary,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (library == null)
            TextButton(
              onPressed: loading ? null : () => openConnect(context, platform),
              child: const Text("Conectar"),
            )
          else
            TextButton(
              onPressed: () => MainShell.goToTab(context, MainShell.libraryTab),
              child: const Text("Ver"),
            ),
        ],
      ),
    );
  }
}
