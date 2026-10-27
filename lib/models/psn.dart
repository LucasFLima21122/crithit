import "library.dart";

/// Contagem de troféus por tipo (definidos num jogo ou ganhos pelo jogador).
class PsnTrophyCounts {
  const PsnTrophyCounts({
    this.platinum = 0,
    this.gold = 0,
    this.silver = 0,
    this.bronze = 0,
  });

  factory PsnTrophyCounts.fromJson(Map<String, dynamic>? json) {
    int read(String key) => (json?[key] as num?)?.toInt() ?? 0;
    return PsnTrophyCounts(
      platinum: read("platinum"),
      gold: read("gold"),
      silver: read("silver"),
      bronze: read("bronze"),
    );
  }

  final int platinum;
  final int gold;
  final int silver;
  final int bronze;

  int get total => platinum + gold + silver + bronze;
}

/// Perfil público de uma conta PSN.
class PsnProfile {
  const PsnProfile({
    required this.accountId,
    required this.onlineId,
    this.avatarUrl,
    this.isPlus = false,
    this.trophyLevel,
    this.earnedTrophies = const PsnTrophyCounts(),
  });

  /// Id numérico interno da Sony; é por ele que se consultam troféus e jogos.
  final String accountId;

  /// O "nome de usuário" da PSN, que a pessoa digita no app.
  final String onlineId;
  final String? avatarUrl;
  final bool isPlus;

  /// Nível de troféus da conta (1 a 999).
  final int? trophyLevel;
  final PsnTrophyCounts earnedTrophies;
}

/// Um jogo da conta PSN: junta a lista de troféus (todos os jogos com
/// troféu, de PS3 a PS5) com o histórico de jogo (tempo jogado, PS4/PS5).
class PsnOwnedGame implements OwnedGame {
  const PsnOwnedGame({
    required this.id,
    required this.name,
    this.consoles = "",
    this.imageUrl,
    this.playtimeMinutes = 0,
    this.lastPlayed,
    this.progress,
    this.earned,
    this.defined,
  });

  /// Chave estável do jogo na PSN (conceito, lista de troféus ou título).
  /// Vira o id do jogo no CritHit: `psn-<id>`.
  final String id;

  @override
  final String name;

  /// Console(s) do jogo, como a Sony devolve: "PS5", "PS4", "PS3,PSVITA"...
  final String consoles;

  /// Arte do jogo (quadrada) ou ícone da lista de troféus.
  final String? imageUrl;

  @override
  final int playtimeMinutes;

  @override
  final DateTime? lastPlayed;

  /// Progresso de troféus de 0 a 100, calculado pela própria Sony (ele
  /// pondera pelo valor de cada troféu, por isso não é ganhos ÷ total).
  final int? progress;

  final PsnTrophyCounts? earned;
  final PsnTrophyCounts? defined;

  @override
  GamePlatform get platform => GamePlatform.psn;

  @override
  bool get wasPlayed => playtimeMinutes > 0 || (earned?.total ?? 0) > 0;

  @override
  bool get hasAchievements => (defined?.total ?? 0) > 0;

  @override
  int? get achievementsUnlocked => earned?.total;

  @override
  int? get achievementsTotal => defined?.total;

  @override
  double get achievementRatio {
    if (!hasAchievements) return 0;
    if (progress != null) return progress! / 100;
    return (earned?.total ?? 0) / defined!.total;
  }

  /// Ganhou o troféu de platina de verdade.
  @override
  bool get isPlatinum => (earned?.platinum ?? 0) > 0;

  /// O jogo tem troféu de platina (nem todo jogo tem, ex.: indies curtos).
  bool get hasPlatinumTrophy => (defined?.platinum ?? 0) > 0;
}

/// Biblioteca PSN importada: o perfil + todos os jogos.
class PsnLibrary with LibraryTotals implements GameLibrary {
  const PsnLibrary({
    required this.profile,
    required this.games,
    required this.fetchedAt,
  });

  final PsnProfile profile;

  @override
  final List<PsnOwnedGame> games;

  @override
  final DateTime fetchedAt;

  @override
  GamePlatform get platform => GamePlatform.psn;

  @override
  String get accountName => profile.onlineId;

  @override
  String? get avatarUrl => profile.avatarUrl;
}
