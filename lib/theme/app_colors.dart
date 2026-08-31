import "package:flutter/material.dart";

/// Paleta oficial da marca CritHit (ver docs/BRANDING.md).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF101012);
  static const Color surface = Color(0xFF19191D);
  static const Color surfaceAlt = Color(0xFF24242A);

  /// Fundo usado na capa de um jogo quando ainda não há imagem real
  /// (ver [GameCover]) — um cinza-azulado sutil, sem apelar pra cor forte.
  static const Color coverBackground = Color(0xFF22303F);

  /// Ação primária (botões, ícones de destaque) — "Mana Blue".
  static const Color primary = Color(0xFF3B82F6);

  /// Cor dedicada às estrelas de avaliação — "Loot Gold".
  static const Color accentGold = Color(0xFFFFC857);

  static const Color textPrimary = Color(0xFFF2F2F5);
  static const Color textSecondary = Color(0xFF9C9CA6);

  /// Estados positivos (ex.: confirmação de review salva) — "Combo Green".
  static const Color success = Color(0xFF4ADE80);

  /// Estados de erro/alerta (ex.: falta escolher uma nota) — "Boss Red".
  static const Color danger = Color(0xFFF87171);
}
