import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/game.dart";
import "../models/review.dart";
import "../models/steam.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../utils/formatters.dart";
import "../widgets/common.dart";
import "../widgets/game_cover.dart";
import "../widgets/platinum_badge.dart";
import "../widgets/review_tile.dart";
import "../widgets/star_rating.dart";
import "main_shell.dart";
import "review_editor_screen.dart";

/// Abre a tela de detalhe de um jogo.
Future<void> openGame(BuildContext context, Game game) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => GameDetailScreen(game: game)),
  );
}

/// Detalhe de um jogo: informações, nota média da comunidade, dados da
/// biblioteca Steam (se o usuário tiver o jogo), a avaliação do usuário e
/// as reviews da comunidade.
class GameDetailScreen extends StatelessWidget {
  const GameDetailScreen({super.key, required this.game});

  final Game game;

  Future<void> _openEditor(BuildContext context, Review? existing) async {
    final String? message = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ReviewEditorScreen(game: game, existing: existing),
      ),
    );
    if (message != null && context.mounted) showCritHitSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Review> reviews = state.reviewsFor(game.id);
    final Review? mine = state.myReviewFor(game.id);
    final List<Review> others = reviews.where((r) => r.id != mine?.id).toList();
    final double average = state.averageFor(game.id);
    final SteamOwnedGame? owned = state.steamEntryFor(game);

    return Scaffold(
      appBar: AppBar(title: Text(game.title, overflow: TextOverflow.ellipsis)),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GameCover(
                        game: game,
                        width: 112,
                        borderRadius: 14,
                        emojiSize: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(game.title, style: textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            if (game.developer != null)
                              Text(
                                game.releaseYear == null
                                    ? game.developer!
                                    : "${game.developer} · ${game.releaseYear}",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _InfoChip(game.genre),
                                for (final String p in game.platform.split(
                                  " / ",
                                ))
                                  _InfoChip(p),
                              ],
                            ),
                            const SizedBox(height: 12),
                            StarRating(rating: average, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              reviews.isEmpty
                                  ? "sem notas ainda"
                                  : "${formatAverage(average)} de média · ${pluralReviews(reviews.length)}",
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (owned != null) ...[
                    const SizedBox(height: 20),
                    _SteamStatsCard(owned: owned),
                  ],
                  const SizedBox(height: 20),
                  Text("Sinopse", style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(game.synopsis, style: textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Text("Sua avaliação", style: textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (mine != null) ...[
                    ReviewTile(review: mine, isMine: true),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditor(context, mine),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text("Editar avaliação"),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Zerou (ou desistiu de) esse jogo? Conta pra gente quantas estrelas ele merece.",
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _openEditor(context, null),
                            icon: const Icon(Icons.star_rounded),
                            label: const Text("Avaliar este jogo"),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text("Reviews da comunidade", style: textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (reviews.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: RatingDistribution(
                        ratings: reviews.map((r) => r.rating).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (others.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        reviews.isEmpty
                            ? "Ainda sem crítica nenhuma. Bora ser o primeiro a dar essa nota?"
                            : "Por enquanto só você avaliou esse jogo.",
                        style: textTheme.bodySmall,
                      ),
                    )
                  else
                    for (final Review review in others)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ReviewTile(review: review),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// Card "Na sua Steam": horas jogadas, última sessão e conquistas.
class _SteamStatsCard extends StatelessWidget {
  const _SteamStatsCard({required this.owned});

  final SteamOwnedGame owned;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_esports_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text("Na sua Steam", style: textTheme.titleMedium),
              ),
              if (owned.isPlatinum) const PlatinumBadge(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: "Tempo de jogo",
                  value: formatPlaytime(owned.playtimeMinutes),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: "Última sessão",
                  value: owned.lastPlayed == null
                      ? "—"
                      : formatRelativeDate(owned.lastPlayed!),
                ),
              ),
            ],
          ),
          if (owned.hasAchievements) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text("Conquistas", style: textTheme.bodySmall),
                const Spacer(),
                Text(
                  "${owned.achievementsUnlocked}/${owned.achievementsTotal} · ${(owned.achievementRatio * 100).round()}%",
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: owned.achievementRatio,
                minHeight: 6,
                color: owned.isPlatinum ? AppColors.success : AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}
