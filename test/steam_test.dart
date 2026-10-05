import "package:flutter_test/flutter_test.dart";

import "package:crithit/models/steam.dart";
import "package:crithit/services/steam/steam_api.dart";
import "package:crithit/services/steam/steam_id_parser.dart";
import "package:crithit/services/steam/steam_library_service.dart";

/// Steam Web API falsa que responde com JSON no formato real da Steam.
class FakeSteamApi implements SteamApi {
  FakeSteamApi(this.responses);

  final Map<String, Map<String, dynamic>> responses;
  final List<(String, Map<String, Object>)> calls = [];

  @override
  Future<Map<String, dynamic>> call(
    String method,
    Map<String, Object> params,
  ) async {
    calls.add((method, params));
    final Map<String, dynamic>? response = responses[method];
    if (response == null) throw const SteamException("falhou");
    return response;
  }
}

const String steamId = "76561198012345678";

Map<String, dynamic> player({int visibility = 3}) => {
  "response": {
    "players": [
      {
        "steamid": steamId,
        "personaname": "lucasf",
        "avatarfull": "https://avatars.steamstatic.com/x_full.jpg",
        "communityvisibilitystate": visibility,
      },
    ],
  },
};

final Map<String, dynamic> ownedGames = {
  "response": {
    "game_count": 3,
    "games": [
      {
        "appid": 1145360,
        "name": "Hades",
        "playtime_forever": 4120,
        "rtime_last_played": 1790000000,
      },
      {"appid": 730, "name": "Counter-Strike 2", "playtime_forever": 900},
      {"appid": 292030, "name": "The Witcher 3", "playtime_forever": 0},
    ],
  },
};

final Map<String, dynamic> achievements = {
  "response": {
    "games": [
      {
        "appid": 1145360,
        "total_achievements": 49,
        "achievements": List.generate(49, (i) => {"statid": i}),
      },
      {"appid": 730, "total_achievements": 0},
    ],
  },
};

void main() {
  group("parseSteamIdInput", () {
    test("aceita SteamID64 puro", () {
      expect(parseSteamIdInput(" $steamId ").steamId, steamId);
    });

    test("aceita link /profiles/", () {
      final SteamIdInput input = parseSteamIdInput(
        "https://steamcommunity.com/profiles/$steamId/",
      );
      expect(input.steamId, steamId);
    });

    test("aceita link /id/ e ID personalizado", () {
      expect(
        parseSteamIdInput(
          "https://steamcommunity.com/id/gabelogannewell/",
        ).vanity,
        "gabelogannewell",
      );
      expect(parseSteamIdInput("meu_nick").vanity, "meu_nick");
    });

    test("rejeita vazio e formatos estranhos", () {
      expect(() => parseSteamIdInput("  "), throwsFormatException);
      expect(
        () => parseSteamIdInput("https://google.com/qualquer coisa"),
        throwsFormatException,
      );
    });
  });

  group("RemoteSteamLibraryService", () {
    test("importa jogos e marca platinados", () async {
      final FakeSteamApi api = FakeSteamApi({
        SteamMethods.getPlayerSummaries: player(),
        SteamMethods.getOwnedGames: ownedGames,
        SteamMethods.getTopAchievementsForGames: achievements,
      });
      final SteamLibrary library = await RemoteSteamLibraryService(
        api,
      ).loadLibrary(steamId);

      expect(library.profile.personaName, "lucasf");
      expect(library.games, hasLength(3));
      expect(library.platinumCount, 1);
      expect(library.playedCount, 2);

      final SteamOwnedGame hades = library.games.firstWhere(
        (g) => g.appId == 1145360,
      );
      expect(hades.isPlatinum, isTrue);
      expect(hades.lastPlayed, isNotNull);

      // Jogo sem conquistas não conta como platinado.
      final SteamOwnedGame cs = library.games.firstWhere((g) => g.appId == 730);
      expect(cs.isPlatinum, isFalse);

      // Só pede conquistas dos jogos que já foram jogados.
      final (String, Map<String, Object>) achievementsCall = api.calls
          .firstWhere((c) => c.$1 == SteamMethods.getTopAchievementsForGames);
      expect(achievementsCall.$2["appids"], [1145360, 730]);
    });

    test("resolve ID personalizado antes de buscar o perfil", () async {
      final FakeSteamApi api = FakeSteamApi({
        SteamMethods.resolveVanityUrl: {
          "response": {"success": 1, "steamid": steamId},
        },
        SteamMethods.getPlayerSummaries: player(),
        SteamMethods.getOwnedGames: ownedGames,
        SteamMethods.getTopAchievementsForGames: achievements,
      });
      await RemoteSteamLibraryService(
        api,
      ).loadLibrary("steamcommunity.com/id/lucasf");
      expect(api.calls.first.$1, SteamMethods.resolveVanityUrl);
      expect(api.calls.first.$2["vanityurl"], "lucasf");
    });

    test("ID personalizado inexistente vira erro amigável", () async {
      final FakeSteamApi api = FakeSteamApi({
        SteamMethods.resolveVanityUrl: {
          "response": {"success": 42, "message": "No match"},
        },
      });
      expect(
        RemoteSteamLibraryService(api).loadLibrary("ninguem_aqui"),
        throwsA(isA<SteamException>()),
      );
    });

    test("perfil privado vira erro com instrução", () async {
      final FakeSteamApi api = FakeSteamApi({
        SteamMethods.getPlayerSummaries: player(visibility: 1),
      });
      expect(
        RemoteSteamLibraryService(api).loadLibrary(steamId),
        throwsA(
          isA<SteamException>().having(
            (e) => e.message,
            "message",
            contains("privado"),
          ),
        ),
      );
    });

    test("detalhes de jogos privados viram erro com instrução", () async {
      final FakeSteamApi api = FakeSteamApi({
        SteamMethods.getPlayerSummaries: player(),
        SteamMethods.getOwnedGames: {"response": <String, dynamic>{}},
      });
      expect(
        RemoteSteamLibraryService(api).loadLibrary(steamId),
        throwsA(
          isA<SteamException>().having(
            (e) => e.message,
            "message",
            contains("Detalhes de jogos"),
          ),
        ),
      );
    });

    test("se as conquistas falharem, a biblioteca ainda carrega", () async {
      final FakeSteamApi api = FakeSteamApi({
        SteamMethods.getPlayerSummaries: player(),
        SteamMethods.getOwnedGames: ownedGames,
      });
      final SteamLibrary library = await RemoteSteamLibraryService(
        api,
      ).loadLibrary(steamId);
      expect(library.games, hasLength(3));
      expect(library.platinumCount, 0);
    });
  });

  test("encodeSteamParams transforma listas em nome[i]", () {
    expect(
      encodeSteamParams({
        "steamid": steamId,
        "appids": [10, 20],
      }),
      {"steamid": steamId, "appids[0]": "10", "appids[1]": "20"},
    );
  });
}
