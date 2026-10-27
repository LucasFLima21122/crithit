import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/game.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "../utils/formatters.dart";
import "game_cover.dart";
import "hud.dart";
import "platinum_badge.dart";

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
    final bool platinum = state
        .ownedEntriesFor(game)
        .any((owned) => owned.isPlatinum);

    return HudPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          GameCover(game: game, width: 50),
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
                const SizedBox(height: 3),
                Text(
                  game.releaseYear == null
                      ? game.genre
                      : "${game.genre} · ${game.releaseYear}",
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (platinum) ...[
                  const SizedBox(height: 6),
                  const PlatinumBadge(),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Placar à direita: a nota é o dado principal do card.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (count == 0)
                Text(
                  "—",
                  style: hudNumberStyle(
                    fontSize: 22,
                    color: AppColors.textMuted,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.accentGold,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      formatAverage(average),
                      style: hudNumberStyle(fontSize: 22),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Text(
                count == 0 ? "SEM NOTA" : pluralReviews(count).toUpperCase(),
                style: hudLabelStyle(
                  fontSize: 9.5,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
