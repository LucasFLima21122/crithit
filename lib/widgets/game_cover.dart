import "package:flutter/material.dart";

import "../theme/app_colors.dart";

/// Mostra a capa de um jogo: usa a imagem real em [coverAsset] quando ela
/// existe no projeto, e cai automaticamente para o [emoji] ilustrativo caso
/// o arquivo ainda não tenha sido adicionado — assim o app nunca quebra por
/// causa de uma imagem que falta.
class GameCover extends StatelessWidget {
  const GameCover({
    super.key,
    required this.emoji,
    this.coverAsset,
    this.size = 56,
    this.borderRadius = 12,
    this.emojiSize = 28,
  });

  final String? coverAsset;
  final String emoji;
  final double size;
  final double borderRadius;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: radius,
        ),
        child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
      );
    }

    final String? asset = coverAsset;
    if (asset == null) return fallback();

    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      ),
    );
  }
}
