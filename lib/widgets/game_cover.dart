import "package:flutter/material.dart";

import "../models/game.dart";
import "../theme/app_colors.dart";
import "../theme/hud_shapes.dart";

/// Capa de um jogo, com fallbacks em cascata para nunca quebrar a tela:
/// capa local (asset) → capa pela internet (ex.: PSN) → capa 2:3 da Steam →
/// banner da Steam → emoji. O recorte corta o canto superior direito, como
/// o "H" do logo.
class GameCover extends StatelessWidget {
  const GameCover({
    super.key,
    required this.game,
    this.width = 56,
    this.height,
    this.cut,
    this.emojiSize = 28,
  });

  final Game game;
  final double width;

  /// Padrão: proporção 2:3 (pôster), igual às capas da Steam.
  final double? height;

  /// Tamanho do corte diagonal. Padrão: proporcional à largura.
  final double? cut;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final double h = height ?? width * 1.5;
    // Decodifica a imagem já no tamanho em que ela aparece: as artes da PSN
    // chegam a 1,5 MB e uma biblioteca real passa de 200 jogos. Pela altura,
    // porque o pôster é vertical e a arte da PSN é quadrada (com `cover`,
    // é a altura que precisa estar completa).
    final int decodeHeight = (h * MediaQuery.devicePixelRatioOf(context))
        .round();

    Widget emoji() {
      return Container(
        width: width,
        height: h,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.coverBackground, AppColors.surface],
          ),
        ),
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
        cacheHeight: decodeHeight,
        // Imagens de CDNs sem CORS (ex.: PSN) entram como <img> na web.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (context, error, stackTrace) => fallback(),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(width: width, height: h, color: AppColors.surfaceAlt),
      );
    }

    Widget steamImages() =>
        network(game.steamCoverUrl, () => network(game.steamHeaderUrl, emoji));

    Widget remoteImages() => network(game.coverUrl, steamImages);

    final String? asset = game.coverAsset;
    final Widget image = asset == null
        ? remoteImages()
        : Image.asset(
            asset,
            width: width,
            height: h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => remoteImages(),
          );

    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: HudShapes.notch(cut: cut ?? (width * 0.14).clamp(6, 22)),
      ),
      child: SizedBox(width: width, height: h, child: image),
    );
  }
}
