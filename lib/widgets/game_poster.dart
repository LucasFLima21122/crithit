import "package:flutter/material.dart";

import "../models/game.dart";
import "../theme/app_colors.dart";
import "game_cover.dart";

/// Pôster vertical de um jogo (capa 2:3 + título + legenda), usado nos
/// carrosséis da tela inicial e na grade da biblioteca Steam.
class GamePoster extends StatelessWidget {
  const GamePoster({
    super.key,
    required this.game,
    required this.onTap,
    this.width = 116,
    this.caption,
    this.overlay,
  });

  final Game game;
  final VoidCallback onTap;
  final double width;

  /// Linha abaixo do título (ex.: estrelas da média, horas jogadas).
  final Widget? caption;

  /// Selo sobre a capa, no canto superior direito (ex.: platinado).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GameCover(
                    game: game,
                    width: width,
                    borderRadius: 12,
                    emojiSize: width / 2.6,
                  ),
                ),
                if (overlay != null)
                  Positioned(top: 6, right: 6, child: overlay!),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              game.title,
              style: textTheme.titleMedium?.copyWith(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (caption != null) ...[
              const SizedBox(height: 4),
              DefaultTextStyle.merge(
                style: const TextStyle(color: AppColors.textSecondary),
                child: caption!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
