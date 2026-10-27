import "package:flutter/material.dart";

import "app_colors.dart";

/// Formas da linguagem visual "HUD" do CritHit.
///
/// A assinatura é o canto cortado em diagonal, tirado do "H" do logo: os
/// painéis cortam o canto superior direito e o inferior esquerdo (como
/// placas de interface de jogo), e as capas cortam só o superior direito,
/// exatamente como o H. Nada de cantos arredondados.
class HudShapes {
  HudShapes._();

  /// Painel com dois cantos opostos cortados (cards, botões, campos).
  static BeveledRectangleBorder panel({
    double cut = 12,
    BorderSide side = BorderSide.none,
  }) {
    return BeveledRectangleBorder(
      side: side,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(cut),
        bottomLeft: Radius.circular(cut),
      ),
    );
  }

  /// Painel com contorno fino, o padrão dos cards.
  static BeveledRectangleBorder outlined({
    double cut = 12,
    Color color = AppColors.stroke,
    double width = 1,
  }) {
    return panel(
      cut: cut,
      side: BorderSide(color: color, width: width),
    );
  }

  /// Só o canto superior direito cortado, como o H do logo (capas, avatar).
  static BeveledRectangleBorder notch({
    double cut = 10,
    BorderSide side = BorderSide.none,
  }) {
    return BeveledRectangleBorder(
      side: side,
      borderRadius: BorderRadius.only(topRight: Radius.circular(cut)),
    );
  }
}
