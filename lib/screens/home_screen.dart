import "dart:ui" show ImageFilter;

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/game.dart";
import "../models/library.dart";
import "../models/review.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "../theme/hud_shapes.dart";
import "../utils/formatters.dart";
import "../widgets/common.dart";
import "../widgets/game_card.dart";
import "../widgets/game_cover.dart";
import "../widgets/game_poster.dart";
import "../widgets/platform_style.dart";
import "../widgets/platinum_badge.dart";
import "../widgets/review_tile.dart";
import "game_detail_screen.dart";
import "main_shell.dart";

/// Aba "Início": destaque da comunidade, jogos em alta, o que você jogou
/// por último (Steam e PlayStation), últimas críticas e o catálogo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(AppState state) async {
    await Future.wait<void>([
      state.refreshReviews(),
      state.refreshSteam(),
      state.refreshPsn(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String firstName = (state.user?.displayName ?? "").split(" ").first;
    final List<Game> top = state.topRated.take(8).toList();
    final List<OwnedGame> recent = state.recentlyPlayed.take(10).toList();
    final List<Review> latest = state.reviews.take(4).toList();
    final bool loadingLibraries = state.loadingSteam || state.loadingPsn;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(state),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TopBar(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "E aí, $firstName!",
                            style: textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "O que você jogou essa semana?",
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.reviewsError != null)
                      _ErrorBanner(
                        message: state.reviewsError!,
                        onRetry: state.refreshReviews,
                      ),
                    if (state.loadingReviews && state.reviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (top.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _HeroCard(game: top.first),
                      ),
                    if (top.length > 1) ...[
                      const SectionHeader(title: "Em alta na comunidade"),
                      _PosterRow(
                        children: [
                          for (final Game game in top.skip(1))
                            GamePoster(
                              game: game,
                              onTap: () => openGame(context, game),
                              caption: ScoreLabel(
                                score: formatAverage(state.averageFor(game.id)),
                                count: state.reviewsFor(game.id).length,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (recent.isNotEmpty) ...[
                      SectionHeader(
                        title: "Continue de onde parou",
                        actionLabel: "Biblioteca",
                        onAction: () =>
                            MainShell.goToTab(context, MainShell.libraryTab),
                      ),
                      _PosterRow(
                        children: [
                          for (final OwnedGame owned in recent)
                            GamePoster(
                              game: state.gameForOwned(owned),
                              onTap: () =>
                                  openGame(context, state.gameForOwned(owned)),
                              overlay: owned.isPlatinum
                                  ? const PlatinumBadge(compact: true)
                                  : null,
                              badge: PlatformTag(platform: owned.platform),
                              caption: Text(
                                owned.playtimeMinutes > 0
                                    ? formatPlaytime(owned.playtimeMinutes)
                                    : "jogado ${formatRelativeDate(owned.lastPlayed!)}",
                                style: textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (!state.hasAnyLibrary || state.psnLibrary == null)
                      _LibraryCallout(
                        loading: loadingLibraries,
                        missingSteam: state.library == null,
                        missingPsn: state.psnLibrary == null,
                        onTap: () =>
                            MainShell.goToTab(context, MainShell.libraryTab),
                      ),
                    if (latest.isNotEmpty) ...[
                      const SectionHeader(title: "Últimas críticas"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            for (final Review review in latest)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ReviewTile(
                                  review: review,
                                  showGameTitle: true,
                                  isMine:
                                      review.userId != null &&
                                      review.userId == state.user?.id,
                                  onTap: () {
                                    final Game? game = state.gameById(
                                      review.gameId,
                                    );
                                    if (game != null) openGame(context, game);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    SectionHeader(
                      title: "Catálogo",
                      actionLabel: "Buscar",
                      onAction: () =>
                          MainShell.goToTab(context, MainShell.searchTab),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (final Game game in state.catalog)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GameCard(
                                game: game,
                                onTap: () => openGame(context, game),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const _Footer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra superior estilo HUD: logo, nome e o nível do jogador.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final int level = context.select<AppState, int>(
      (state) => state.playerLevel.level,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
      child: Row(
        children: [
          ClipPath(
            clipper: ShapeBorderClipper(shape: HudShapes.notch(cut: 8)),
            child: Image.asset(
              "assets/branding/logo.png",
              width: 34,
              height: 34,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Text("🎮", style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 10),
          Text("CRITHIT", style: hudLabelStyle(fontSize: 20, letterSpacing: 3)),
          const Spacer(),
          Tooltip(
            message: "Seu nível de crítico",
            child: HudPanel(
              cut: 7,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderColor: AppColors.primary.withValues(alpha: 0.6),
              onTap: () => MainShell.goToTab(context, MainShell.profileTab),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "LV",
                    style: hudLabelStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text("$level", style: hudNumberStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Destaque da comunidade: o jogo mais bem avaliado, com a capa ampliada e
/// desfocada ao fundo, a nota em tamanho de "dano crítico" e a crítica mais
/// recente dele.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Review> reviews = state.reviewsFor(game.id);
    final Review? quote = reviews.where((r) => r.hasComment).firstOrNull;

    return Material(
      color: AppColors.surface,
      shape: HudShapes.outlined(cut: 18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openGame(context, game),
        child: Stack(
          children: [
            // Fundo: a própria capa, ampliada e desfocada.
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Opacity(
                  opacity: 0.45,
                  child: GameCover(game: game, width: 600, height: 600),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.background.withValues(alpha: 0.2),
                      AppColors.background.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GameCover(game: game, width: 104, emojiSize: 44),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HudTag(
                          label: "Destaque da comunidade",
                          color: Colors.white,
                          background: AppColors.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          game.title,
                          style: textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatAverage(state.averageFor(game.id)),
                              style: hudNumberStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 4),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Icon(
                                Icons.star_rounded,
                                color: AppColors.accentGold,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  pluralReviews(reviews.length),
                                  style: textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (quote != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            "“${quote.comment}”",
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "— ${quote.authorName}",
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carrossel horizontal de pôsteres.
class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// Convite para importar as bibliotecas que ainda faltam.
class _LibraryCallout extends StatelessWidget {
  const _LibraryCallout({
    required this.onTap,
    required this.loading,
    required this.missingSteam,
    required this.missingPsn,
  });

  final VoidCallback onTap;
  final bool loading;
  final bool missingSteam;
  final bool missingPsn;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String title = loading
        ? "Importando suas bibliotecas..."
        : missingSteam && missingPsn
        ? "Traga seus jogos pro CritHit"
        : missingPsn
        ? "Também joga no PlayStation?"
        : "Também joga no PC?";
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: HudPanel(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        borderColor: AppColors.primary.withValues(alpha: 0.5),
        child: Row(
          children: [
            Column(
              children: [
                if (missingSteam)
                  Icon(
                    GamePlatform.steam.icon,
                    color: GamePlatform.steam.color,
                    size: 26,
                  ),
                if (missingSteam && missingPsn) const SizedBox(height: 6),
                if (missingPsn)
                  Icon(
                    GamePlatform.psn.icon,
                    color: GamePlatform.psn.color,
                    size: 26,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    missingSteam && missingPsn
                        ? "Conecte a Steam e a PSN: todos os seus jogos, horas, troféus e platinas, sem cadastrar um por um."
                        : missingPsn
                        ? "Conecte sua conta PSN e veja troféus e platinas ao lado da sua Steam."
                        : "Conecte sua Steam e veja horas e conquistas ao lado da sua PSN.",
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: HudPanel(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        color: AppColors.danger.withValues(alpha: 0.12),
        borderColor: AppColors.danger.withValues(alpha: 0.5),
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.danger,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text("Tentar de novo")),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            ClipPath(
              clipper: ShapeBorderClipper(shape: HudShapes.notch(cut: 14)),
              child: Image.asset(
                "assets/branding/logo.png",
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Text("🎮", style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "CADA JOGO MERECE UMA CRÍTICA.",
              style: hudLabelStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
