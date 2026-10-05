import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/game.dart";
import "../models/steam.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../utils/formatters.dart";
import "game_cover.dart";
import "platinum_badge.dart";
import "star_rating.dart";

/// Card horizontal de um jogo (capa + título + nota média), usado nas listas.
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game, required this.onTap});

  final Game game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppState state = context.watch<AppState>();
    final int count = state.reviewsFor(game.id).length;
    final double average = state.averageFor(game.id);
    final SteamOwnedGame? owned = state.steamEntryFor(game);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              GameCover(game: game, width: 52, borderRadius: 10),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      game.releaseYear == null
                          ? game.genre
                          : "${game.genre} · ${game.releaseYear}",
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StarRating(rating: average, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            count == 0
                                ? "sem notas ainda"
                                : "${formatAverage(average)} ($count)",
                            style: textTheme.bodySmall,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (owned != null && owned.isPlatinum) ...[
                const SizedBox(width: 8),
                const PlatinumBadge(compact: true),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
