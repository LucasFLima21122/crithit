/// Plataformas de onde o CritHit importa bibliotecas de jogos.
enum GamePlatform {
  steam("Steam"),
  psn("PlayStation");

  const GamePlatform(this.label);
  final String label;
}

/// Um jogo de uma biblioteca importada, seja da Steam ou da PlayStation.
///
/// As telas (biblioteca, "Continue de onde parou", detalhe do jogo) só
/// conhecem esta interface, então uma plataforma nova não muda nenhuma tela.
abstract interface class OwnedGame {
  GamePlatform get platform;
  String get name;

  /// `0` quando a plataforma não informa o tempo de jogo.
  int get playtimeMinutes;
  DateTime? get lastPlayed;
  bool get wasPlayed;

  /// Conquistas (Steam) ou troféus (PlayStation).
  bool get hasAchievements;
  int? get achievementsUnlocked;
  int? get achievementsTotal;

  /// Progresso de 0 a 1.
  double get achievementRatio;

  /// Steam: 100% das conquistas. PlayStation: ganhou o troféu de platina.
  bool get isPlatinum;
}

/// Uma biblioteca importada: a conta na plataforma + todos os jogos.
abstract interface class GameLibrary {
  GamePlatform get platform;

  /// Nome público da conta (persona da Steam, ID online da PSN).
  String get accountName;
  String? get avatarUrl;
  List<OwnedGame> get games;
  DateTime get fetchedAt;
  int get totalPlaytimeMinutes;
  int get playedCount;
  int get platinumCount;
}

/// Soma, contagem de jogados e de platinas: igual para qualquer plataforma.
mixin LibraryTotals implements GameLibrary {
  @override
  int get totalPlaytimeMinutes =>
      games.fold(0, (sum, game) => sum + game.playtimeMinutes);

  @override
  int get playedCount => games.where((g) => g.wasPlayed).length;

  @override
  int get platinumCount => games.where((g) => g.isPlatinum).length;
}
