/// Perfil público de uma conta Steam (ISteamUser/GetPlayerSummaries).
class SteamProfile {
  const SteamProfile({
    required this.steamId,
    required this.personaName,
    this.avatarUrl,
    this.profileUrl,
    this.isPublic = true,
  });

  /// SteamID64 — 17 dígitos, sempre começando com 7656119.
  final String steamId;
  final String personaName;
  final String? avatarUrl;
  final String? profileUrl;

  /// `communityvisibilitystate == 3` na API da Steam.
  final bool isPublic;
}

/// Um jogo da biblioteca Steam do usuário, com tempo de jogo e progresso
/// de conquistas.
class SteamOwnedGame {
  const SteamOwnedGame({
    required this.appId,
    required this.name,
    required this.playtimeMinutes,
    this.lastPlayed,
    this.achievementsUnlocked,
    this.achievementsTotal,
  });

  final int appId;
  final String name;
  final int playtimeMinutes;
  final DateTime? lastPlayed;

  /// `null` quando a Steam não informou o progresso (ex.: jogo nunca aberto).
  final int? achievementsUnlocked;

  /// `0` quando o jogo não tem conquistas.
  final int? achievementsTotal;

  bool get wasPlayed => playtimeMinutes > 0;

  bool get hasAchievements => (achievementsTotal ?? 0) > 0;

  /// "Platinou": desbloqueou 100% das conquistas — o equivalente Steam ao
  /// troféu de platina do PlayStation.
  bool get isPlatinum =>
      hasAchievements && achievementsUnlocked == achievementsTotal;

  double get achievementRatio =>
      hasAchievements ? (achievementsUnlocked ?? 0) / achievementsTotal! : 0;

  SteamOwnedGame withAchievements({required int unlocked, required int total}) {
    return SteamOwnedGame(
      appId: appId,
      name: name,
      playtimeMinutes: playtimeMinutes,
      lastPlayed: lastPlayed,
      achievementsUnlocked: unlocked,
      achievementsTotal: total,
    );
  }
}

/// Biblioteca Steam importada: o perfil + todos os jogos.
class SteamLibrary {
  const SteamLibrary({
    required this.profile,
    required this.games,
    required this.fetchedAt,
  });

  final SteamProfile profile;
  final List<SteamOwnedGame> games;
  final DateTime fetchedAt;

  int get totalPlaytimeMinutes =>
      games.fold(0, (sum, game) => sum + game.playtimeMinutes);

  int get playedCount => games.where((g) => g.wasPlayed).length;

  int get platinumCount => games.where((g) => g.isPlatinum).length;
}
