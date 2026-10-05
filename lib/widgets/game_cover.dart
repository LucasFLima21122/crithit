import "package:flutter/material.dart";

import "../models/game.dart";
import "../theme/app_colors.dart";

/// Capa de um jogo, com fallbacks em cascata para nunca quebrar a tela:
/// capa local (asset) → capa 2:3 da Steam → banner da Steam → emoji.
class GameCover extends StatelessWidget {
  const GameCover({
    super.key,
    required this.game,
    this.width = 56,
    this.height,
    this.borderRadius = 12,
    this.emojiSize = 28,
  });

  final Game game;
  final double width;

  /// Padrão: proporção 2:3 (pôster), igual às capas da Steam.
  final double? height;
  final double borderRadius;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final double h = height ?? width * 1.5;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    Widget emoji() {
      return Container(
        width: width,
        height: h,
        alignment: Alignment.center,
        color: AppColors.coverBackground,
        child: Text(game.emoji, style: TextStyle(fontSize: emojiSize)),
      );
    }

    Widget network(String? url, Widget Function() fallback) {
      if (url == null) return fallback();
      return Image.network(
        url,
        width: width,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(width: width, height: h, color: AppColors.surfaceAlt),
      );
    }

    Widget steamImages() =>
        network(game.steamCoverUrl, () => network(game.steamHeaderUrl, emoji));

    final String? asset = game.coverAsset;
    final Widget image = asset == null
        ? steamImages()
        : Image.asset(
            asset,
            width: width,
            height: h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => steamImages(),
          );

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: width, height: h, child: image),
    );
  }
}
