import "dart:math" as math;

/// Nível de "crítico" do jogador, mostrado na ficha do perfil.
///
/// É o toque de RPG da marca: cada crítica, hora jogada e platina vira XP.
/// A conta é simples e transparente de propósito (aparece explicada no
/// próprio app):
///   - crítica com texto: 100 XP; só a nota: 50 XP
///   - platina (Steam ou PSN): 250 XP
///   - cada hora jogada nas bibliotecas importadas: 1 XP
class PlayerLevel {
  const PlayerLevel._(this.xp);

  factory PlayerLevel.from({
    required int reviewsWithText,
    required int ratingsOnly,
    required int platinums,
    required int playtimeMinutes,
  }) {
    return PlayerLevel._(
      reviewsWithText * xpPerReview +
          ratingsOnly * xpPerRating +
          platinums * xpPerPlatinum +
          playtimeMinutes ~/ 60,
    );
  }

  static const int xpPerReview = 100;
  static const int xpPerRating = 50;
  static const int xpPerPlatinum = 250;

  final int xp;

  /// O nível N começa em 60 × (N − 1)² XP: os primeiros níveis sobem
  /// rápido e os altos pedem dedicação.
  static int xpForLevel(int level) => 60 * (level - 1) * (level - 1);

  int get level => math.sqrt(xp / 60).floor() + 1;

  int get currentLevelXp => xpForLevel(level);
  int get nextLevelXp => xpForLevel(level + 1);

  /// Progresso dentro do nível atual, de 0 a 1.
  double get progress => (xp - currentLevelXp) / (nextLevelXp - currentLevelXp);

  int get xpToNext => nextLevelXp - xp;

  /// Título do jogador conforme o nível.
  String get rank {
    if (level >= 12) return "Lenda";
    if (level >= 8) return "Veterano";
    if (level >= 5) return "Crítico";
    if (level >= 3) return "Aventureiro";
    return "Novato";
  }
}
