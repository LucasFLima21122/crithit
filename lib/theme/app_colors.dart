import "package:flutter/material.dart";

/// Paleta oficial da marca CritHit, v2 do Checkpoint 6 (ver docs/BRANDING.md).
///
/// Base escura neutra (a mesma do fundo do logo) e acentos com significado:
/// vermelho é a cor da marca e da ação, dourado só nas estrelas, verde e
/// laranja só em feedback, e o "platina" só no selo de platina.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF101012);
  static const Color surface = Color(0xFF18181D);
  static const Color surfaceAlt = Color(0xFF222229);

  /// Linhas finas dos painéis HUD (contornos, divisórias, trilhos de barra).
  static const Color stroke = Color(0xFF2E2E37);

  /// Fundo da capa de um jogo quando ainda não há imagem real
  /// (ver [GameCover]).
  static const Color coverBackground = Color(0xFF26222B);

  /// Cor da marca e da ação primária — "Crit Red", o vermelho do dano
  /// crítico nos jogos. É também a cor do "H" do logo.
  static const Color primary = Color(0xFFFF4655);

  /// Variação escura do Crit Red, para gradientes e estados pressionados.
  static const Color primaryDeep = Color(0xFFB3212F);

  /// Cor dedicada às estrelas de avaliação — "Loot Gold".
  static const Color accentGold = Color(0xFFFFC857);

  static const Color textPrimary = Color(0xFFF2F2F5);
  static const Color textSecondary = Color(0xFF9C9CA6);
  static const Color textMuted = Color(0xFF6B6B76);

  /// Estados positivos (ex.: review salva) — "Combo Green".
  static const Color success = Color(0xFF3DDC97);

  /// Erros e alertas — "Boss Orange". Laranja, e não vermelho, para não se
  /// confundir com o Crit Red da marca.
  static const Color danger = Color(0xFFFF8A3D);

  /// Selo de platina (100% das conquistas na Steam, troféu de platina na
  /// PlayStation) — "Platinum".
  static const Color platinum = Color(0xFFC9D7EE);

  /// Cores das plataformas, usadas só nos ícones e etiquetas de cada uma.
  static const Color steam = Color(0xFF66C0F4);
  static const Color playstation = Color(0xFF2E8BFF);
}
