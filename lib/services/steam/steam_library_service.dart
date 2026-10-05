import "../../data/mock_steam_library.dart";
import "../../models/steam.dart";
import "steam_api.dart";
import "steam_id_parser.dart";

/// Importa a biblioteca Steam de um usuário: perfil, jogos, horas jogadas
/// e progresso de conquistas (para saber o que foi platinado).
abstract class SteamLibraryService {
  /// `true` quando os dados são de demonstração (modo offline sem chave).
  bool get isDemo;

  /// [input] é o que o usuário digitou: link do perfil, ID personalizado ou
  /// SteamID64 (ver [parseSteamIdInput]).
  Future<SteamLibrary> loadLibrary(String input);
}

class RemoteSteamLibraryService implements SteamLibraryService {
  RemoteSteamLibraryService(this._api);

  final SteamApi _api;

  /// Quantos appids mandar por chamada de conquistas.
  static const int _achievementsBatchSize = 100;

  @override
  bool get isDemo => false;

  @override
  Future<SteamLibrary> loadLibrary(String input) async {
    final String steamId = await resolveSteamId(input);
    final SteamProfile profile = await fetchProfile(steamId);
    if (!profile.isPublic) {
      throw const SteamException(
        "Esse perfil da Steam é privado. Em Privacidade, deixe \"Meu perfil\" e \"Detalhes de jogos\" como Público.",
      );
    }
    final List<SteamOwnedGame> owned = await fetchOwnedGames(steamId);
    final List<SteamOwnedGame> games = await attachAchievements(steamId, owned);
    return SteamLibrary(
      profile: profile,
      games: games,
      fetchedAt: DateTime.now(),
    );
  }

  Future<String> resolveSteamId(String input) async {
    final SteamIdInput parsed;
    try {
      parsed = parseSteamIdInput(input);
    } on FormatException catch (error) {
      throw SteamException(error.message);
    }
    if (parsed.steamId != null) return parsed.steamId!;

    final Map<String, dynamic> json = await _api.call(
      SteamMethods.resolveVanityUrl,
      <String, Object>{"vanityurl": parsed.vanity!},
    );
    final Map<String, dynamic> response = _response(json);
    if (response["success"] != 1 || response["steamid"] == null) {
      throw SteamException(
        "Não achei nenhum perfil da Steam com o ID \"${parsed.vanity}\".",
      );
    }
    return response["steamid"] as String;
  }

  Future<SteamProfile> fetchProfile(String steamId) async {
    final Map<String, dynamic> json = await _api.call(
      SteamMethods.getPlayerSummaries,
      <String, Object>{"steamids": steamId},
    );
    final List<dynamic> players =
        (_response(json)["players"] as List<dynamic>?) ?? <dynamic>[];
    if (players.isEmpty) {
      throw const SteamException(
        "Não achei nenhum perfil da Steam com esse ID.",
      );
    }
    final Map<String, dynamic> player = players.first as Map<String, dynamic>;
    return SteamProfile(
      steamId: player["steamid"] as String,
      personaName: player["personaname"] as String? ?? "Jogador Steam",
      avatarUrl: player["avatarfull"] as String?,
      profileUrl: player["profileurl"] as String?,
      isPublic: player["communityvisibilitystate"] == 3,
    );
  }

  Future<List<SteamOwnedGame>> fetchOwnedGames(String steamId) async {
    final Map<String, dynamic> json = await _api.call(
      SteamMethods.getOwnedGames,
      <String, Object>{
        "steamid": steamId,
        "include_appinfo": 1,
        "include_played_free_games": 1,
      },
    );
    final Map<String, dynamic> response = _response(json);
    // Com "Detalhes de jogos" privado a Steam devolve `response: {}`.
    if (!response.containsKey("games")) {
      throw const SteamException(
        "Não consegui ver seus jogos. Na Steam, em Privacidade, deixe \"Detalhes de jogos\" como Público (e desmarque \"Sempre manter meu tempo de jogo privado\").",
      );
    }
    return (response["games"] as List<dynamic>).map((dynamic raw) {
      final Map<String, dynamic> game = raw as Map<String, dynamic>;
      final int lastPlayed = (game["rtime_last_played"] as num?)?.toInt() ?? 0;
      return SteamOwnedGame(
        appId: (game["appid"] as num).toInt(),
        name: game["name"] as String? ?? "App ${game["appid"]}",
        playtimeMinutes: (game["playtime_forever"] as num?)?.toInt() ?? 0,
        lastPlayed: lastPlayed > 0
            ? DateTime.fromMillisecondsSinceEpoch(lastPlayed * 1000)
            : null,
      );
    }).toList();
  }

  /// Busca o progresso de conquistas dos jogos já jogados, em lotes. Se a
  /// Steam falhar aqui, a biblioteca continua aparecendo — só sem conquistas.
  Future<List<SteamOwnedGame>> attachAchievements(
    String steamId,
    List<SteamOwnedGame> games,
  ) async {
    final List<int> played = games
        .where((g) => g.wasPlayed)
        .map((g) => g.appId)
        .toList();
    final Map<int, (int, int)> progress = <int, (int, int)>{};

    for (
      int start = 0;
      start < played.length;
      start += _achievementsBatchSize
    ) {
      final List<int> batch = played.sublist(
        start,
        (start + _achievementsBatchSize).clamp(0, played.length),
      );
      try {
        // Com max_achievements alto, a Steam devolve TODAS as conquistas
        // desbloqueadas de cada jogo, então o total desbloqueado é o tamanho
        // dessa lista. A Edge Function já resume isso em `unlocked_count`
        // para não trafegar centenas de KB.
        final Map<String, dynamic> json = await _api.call(
          SteamMethods.getTopAchievementsForGames,
          <String, Object>{
            "steamid": steamId,
            "max_achievements": 10000,
            "appids": batch,
          },
        );
        final List<dynamic> items =
            (_response(json)["games"] as List<dynamic>?) ?? <dynamic>[];
        for (final dynamic raw in items) {
          final Map<String, dynamic> item = raw as Map<String, dynamic>;
          final int unlocked =
              (item["unlocked_count"] as num?)?.toInt() ??
              (item["achievements"] as List<dynamic>?)?.length ??
              0;
          progress[(item["appid"] as num).toInt()] = (
            unlocked,
            (item["total_achievements"] as num?)?.toInt() ?? 0,
          );
        }
      } on SteamException {
        break;
      }
    }

    return games.map((SteamOwnedGame game) {
      final (int, int)? p = progress[game.appId];
      return p == null
          ? game
          : game.withAchievements(unlocked: p.$1, total: p.$2);
    }).toList();
  }

  Map<String, dynamic> _response(Map<String, dynamic> json) {
    return (json["response"] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }
}

/// Biblioteca de demonstração (modo offline): qualquer ID carrega o perfil
/// `crithit_demo`. Digitar "privado" simula o erro de perfil privado.
class DemoSteamLibraryService implements SteamLibraryService {
  @override
  bool get isDemo => true;

  @override
  Future<SteamLibrary> loadLibrary(String input) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (input.toLowerCase().contains("privado")) {
      throw const SteamException(
        "Esse perfil da Steam é privado. Em Privacidade, deixe \"Meu perfil\" e \"Detalhes de jogos\" como Público.",
      );
    }
    return SteamLibrary(
      profile: kDemoSteamProfile,
      games: buildDemoSteamGames(),
      fetchedAt: DateTime.now(),
    );
  }
}
