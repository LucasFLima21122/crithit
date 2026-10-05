import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/game.dart";
import "../models/review.dart";
import "../models/steam.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../utils/formatters.dart";
import "../widgets/common.dart";
import "../widgets/game_card.dart";
import "../widgets/game_poster.dart";
import "../widgets/platinum_badge.dart";
import "../widgets/review_tile.dart";
import "../widgets/star_rating.dart";
import "game_detail_screen.dart";
import "main_shell.dart";

/// Aba "Início": destaques da comunidade, jogos Steam recentes, últimas
/// críticas e o catálogo completo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(AppState state) async {
    await Future.wait<void>([state.refreshReviews(), state.refreshSteam()]);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String firstName = (state.user?.displayName ?? "").split(" ").first;
    final List<Game> top = state.topRated.take(8).toList();
    final List<SteamOwnedGame> recent = state.recentlyPlayed.take(10).toList();
    final List<Review> latest = state.reviews.take(4).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("CritHit"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                "assets/branding/logo.png",
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Text("🎮", style: TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(state),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
                  if (top.isNotEmpty) ...[
                    const SectionHeader(title: "Em alta na comunidade"),
                    _PosterRow(
                      children: [
                        for (final Game game in top)
                          GamePoster(
                            game: game,
                            onTap: () => openGame(context, game),
                            caption: Row(
                              children: [
                                const StarRating(
                                  rating: 1,
                                  maxRating: 1,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "${formatAverage(state.averageFor(game.id))} · ${state.reviewsFor(game.id).length}",
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (state.library != null && recent.isNotEmpty) ...[
                    SectionHeader(
                      title: "Continue de onde parou",
                      actionLabel: "Biblioteca",
                      onAction: () =>
                          MainShell.goToTab(context, MainShell.libraryTab),
                    ),
                    _PosterRow(
                      children: [
                        for (final SteamOwnedGame owned in recent)
                          GamePoster(
                            game: state.gameForSteam(owned),
                            onTap: () =>
                                openGame(context, state.gameForSteam(owned)),
                            overlay: owned.isPlatinum
                                ? const PlatinumBadge(compact: true)
                                : null,
                            caption: Text(
                              formatPlaytime(owned.playtimeMinutes),
                              style: textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ] else if (state.library == null)
                    _SteamCallout(
                      loading: state.loadingSteam,
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
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

class _SteamCallout extends StatelessWidget {
  const _SteamCallout({required this.onTap, required this.loading});

  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_esports_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loading
                            ? "Importando sua Steam..."
                            : "Importe sua biblioteca Steam",
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Todos os seus jogos, horas jogadas e platinas — sem cadastrar um por um.",
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                "assets/branding/logo.png",
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Text("🎮", style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Cada jogo merece uma crítica.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
