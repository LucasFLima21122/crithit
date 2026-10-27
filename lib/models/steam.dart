import "library.dart";

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
class SteamOwnedGame implements OwnedGame {
  const SteamOwnedGame({
    required this.appId,
    required this.name,
    required this.playtimeMinutes,
    this.lastPlayed,
    this.achievementsUnlocked,
    this.achievementsTotal,
  });

  final int appId;
  @override
  final String name;
  @override
  final int playtimeMinutes;
  @override
  final DateTime? lastPlayed;

  /// `null` quando a Steam não informou o progresso (ex.: jogo nunca aberto).
  @override
  final int? achievementsUnlocked;

  /// `0` quando o jogo não tem conquistas.
  @override
  final int? achievementsTotal;

  @override
  GamePlatform get platform => GamePlatform.steam;

  @override
  bool get wasPlayed => playtimeMinutes > 0;

  @override
  bool get hasAchievements => (achievementsTotal ?? 0) > 0;

  /// "Platinou": desbloqueou 100% das conquistas — o equivalente Steam ao
  /// troféu de platina do PlayStation.
  @override
  bool get isPlatinum =>
      hasAchievements && achievementsUnlocked == achievementsTotal;

  @override
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
class SteamLibrary with LibraryTotals implements GameLibrary {
  const SteamLibrary({
    required this.profile,
    required this.games,
    required this.fetchedAt,
  });

  final SteamProfile profile;
  @override
  final List<SteamOwnedGame> games;
  @override
  final DateTime fetchedAt;

  @override
  GamePlatform get platform => GamePlatform.steam;

  @override
  String get accountName => profile.personaName;

  @override
  String? get avatarUrl => profile.avatarUrl;
}
