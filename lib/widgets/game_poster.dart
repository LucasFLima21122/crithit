import "package:flutter/material.dart";

import "../models/game.dart";
import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "game_cover.dart";

/// Pôster vertical de um jogo (capa 2:3 + título + legenda), usado nos
/// carrosséis da tela inicial e na grade da biblioteca.
class GamePoster extends StatelessWidget {
  const GamePoster({
    super.key,
    required this.game,
    required this.onTap,
    this.width = 116,
    this.caption,
    this.overlay,
    this.badge,
  });

  final Game game;
  final VoidCallback onTap;
  final double width;

  /// Linha abaixo do título (ex.: nota média, horas jogadas).
  final Widget? caption;

  /// Selo sobre a capa, no canto superior esquerdo (ex.: platina). O canto
  /// direito fica livre por causa do corte.
  final Widget? overlay;

  /// Etiqueta no pé da capa (ex.: plataforma).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: GameCover(
                    game: game,
                    width: width,
                    emojiSize: width / 2.6,
                  ),
                ),
                // Fio vermelho no pé da capa: a "barra de vida" do pôster.
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: width * 0.32,
                    height: 3,
                    color: AppColors.primary,
                  ),
                ),
                if (overlay != null)
                  Positioned(top: 6, left: 6, child: overlay!),
                if (badge != null)
                  Positioned(bottom: 9, left: 6, child: badge!),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              game.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 14, height: 1.15),
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

/// Nota média em destaque: número grande + estrela dourada.
class ScoreLabel extends StatelessWidget {
  const ScoreLabel({
    super.key,
    required this.score,
    this.count,
    this.fontSize = 14,
  });

  /// Texto já formatado (ex.: "4,8").
  final String score;
  final int? count;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.star_rounded,
          size: fontSize + 2,
          color: AppColors.accentGold,
        ),
        const SizedBox(width: 3),
        Text(score, style: hudNumberStyle(fontSize: fontSize)),
        if (count != null) ...[
          const SizedBox(width: 5),
          Text("($count)", style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
