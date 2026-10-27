import "dart:ui" show ImageFilter;

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/game.dart";
import "../models/library.dart";
import "../models/psn.dart";
import "../models/review.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "../utils/formatters.dart";
import "../widgets/common.dart";
import "../widgets/game_cover.dart";
import "../widgets/platform_style.dart";
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

/// Detalhe de um jogo: informações, nota média da comunidade, os dados das
/// bibliotecas do usuário (Steam e/ou PlayStation), a avaliação dele e as
/// reviews da comunidade.
class GameDetailScreen extends StatelessWidget {
  const GameDetailScreen({super.key, required this.game});

  final Game game;

  Future<void> _openEditor(BuildContext context, Review? existing) async {
    final ReviewEditorResult? result = await Navigator.of(context)
        .push<ReviewEditorResult>(
          MaterialPageRoute<ReviewEditorResult>(
            builder: (_) => ReviewEditorScreen(game: game, existing: existing),
          ),
        );
    if (result == null || !context.mounted) return;
    showCritHitSnack(context, result.message);
    final int? rating = result.rating;
    if (rating != null) showCritBurst(context, rating: rating, xp: result.xp);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Review> reviews = state.reviewsFor(game.id);
    final Review? mine = state.myReviewFor(game.id);
    final List<Review> others = reviews.where((r) => r.id != mine?.id).toList();
    final List<OwnedGame> owned = state.ownedEntriesFor(game);

    return Scaffold(
      appBar: AppBar(title: Text(game.title, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(game: game, reviews: reviews),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final OwnedGame entry in owned) ...[
                        const SizedBox(height: 12),
                        _OwnedStatsCard(owned: entry),
                      ],
                    ],
                  ),
                ),
                const SectionHeader(title: "Sinopse"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(game.synopsis, style: textTheme.bodyMedium),
                ),
                const SectionHeader(title: "Sua avaliação"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: mine != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReviewTile(review: mine, isMine: true),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => _openEditor(context, mine),
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text("Editar avaliação"),
                            ),
                          ],
                        )
                      : HudPanel(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Zerou (ou desistiu de) esse jogo? Conta pra gente quantas estrelas ele merece.",
                                style: textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () => _openEditor(context, null),
                                icon: const Icon(Icons.star_rounded),
                                label: const Text("Avaliar este jogo"),
                              ),
                            ],
                          ),
                        ),
                ),
                const SectionHeader(title: "Reviews da comunidade"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (reviews.isNotEmpty) ...[
                        HudPanel(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabeçalho: capa, ficha técnica e a nota da comunidade em destaque, com a
/// capa ampliada e desfocada ao fundo.
class _Header extends StatelessWidget {
  const _Header({required this.game, required this.reviews});

  final Game game;
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double average = reviews.isEmpty
        ? 0
        : reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;

    return Stack(
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Opacity(
              opacity: 0.35,
              child: GameCover(game: game, width: 600, height: 600),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.background],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameCover(game: game, width: 116, emojiSize: 48),
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        HudTag(label: game.genre, color: AppColors.textPrimary),
                        for (final String p in game.platform.split(" / "))
                          HudTag(label: p),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (reviews.isEmpty)
                      Text("sem notas ainda", style: textTheme.bodySmall)
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatAverage(average),
                            style: hudNumberStyle(fontSize: 38),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StarRating(rating: average, size: 18),
                                Text(
                                  "média · ${pluralReviews(reviews.length)}",
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card "Na sua Steam" / "Na sua PlayStation": horas, última sessão e
/// conquistas ou troféus.
class _OwnedStatsCard extends StatelessWidget {
  const _OwnedStatsCard({required this.owned});

  final OwnedGame owned;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final GamePlatform platform = owned.platform;
    final OwnedGame entry = owned;
    final PsnTrophyCounts? earned = entry is PsnOwnedGame ? entry.earned : null;

    return HudPanel(
      borderColor: platform.color.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(platform.icon, size: 18, color: platform.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Na sua ${platform.label}",
                  style: textTheme.titleMedium,
                ),
              ),
              if (owned.isPlatinum) const PlatinumBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: "Tempo de jogo",
                  value: owned.playtimeMinutes > 0
                      ? formatPlaytime(owned.playtimeMinutes)
                      : owned.wasPlayed
                      ? "—"
                      : "nunca jogado",
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
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  platform.achievementsLabel.toUpperCase(),
                  style: hudLabelStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  "${owned.achievementsUnlocked ?? 0}/${owned.achievementsTotal} · ${(owned.achievementRatio * 100).round()}%",
                  style: hudNumberStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedBar(
              value: owned.achievementRatio,
              segments: 20,
              color: owned.isPlatinum ? AppColors.platinum : platform.color,
            ),
          ],
          if (earned != null && earned.total > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _TrophyCount(
                  label: "Platina",
                  count: earned.platinum,
                  color: AppColors.platinum,
                ),
                _TrophyCount(
                  label: "Ouro",
                  count: earned.gold,
                  color: const Color(0xFFE3B341),
                ),
                _TrophyCount(
                  label: "Prata",
                  count: earned.silver,
                  color: const Color(0xFFB7BDC8),
                ),
                _TrophyCount(
                  label: "Bronze",
                  count: earned.bronze,
                  color: const Color(0xFFC8875A),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Contador de um tipo de troféu da PSN (cores dos próprios troféus).
class _TrophyCount extends StatelessWidget {
  const _TrophyCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: Row(
          children: [
            Icon(Icons.emoji_events_rounded, size: 15, color: color),
            const SizedBox(width: 4),
            Text("$count", style: hudNumberStyle(fontSize: 14)),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: hudLabelStyle(fontSize: 10.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(value, style: hudNumberStyle(fontSize: 18)),
      ],
    );
  }
}
