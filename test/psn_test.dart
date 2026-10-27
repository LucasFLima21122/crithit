import "package:flutter_test/flutter_test.dart";

import "package:crithit/models/game.dart";
import "package:crithit/models/psn.dart";
import "package:crithit/services/psn/psn_api.dart";
import "package:crithit/services/psn/psn_library_service.dart";

/// PsnApi falsa: responde por ação com JSON no formato real da Sony, ou
/// lança o erro configurado.
class FakePsnApi implements PsnApi {
  FakePsnApi(this.responses);

  final Map<String, Object> responses;
  final List<String> calls = <String>[];

  @override
  Future<Map<String, dynamic>> call(
    String action,
    Map<String, Object> params,
  ) async {
    calls.add(action);
    final Object? response = responses[action];
    if (response is PsnException) throw response;
    return response! as Map<String, dynamic>;
  }
}

const Map<String, dynamic> _profile = <String, dynamic>{
  "profile": <String, dynamic>{
    "onlineId": "Kratos_BR",
    "accountId": "4867310985213458192",
    "avatarUrls": <dynamic>[
      <String, dynamic>{
        "size": "l",
        "avatarUrl":
            "http://static-resource.np.community.playstation.net/avatar/a.png",
      },
    ],
    "plus": 1,
    "trophySummary": <String, dynamic>{
      "level": 233,
      "progress": 41,
      "earnedTrophies": <String, dynamic>{
        "platinum": 2,
        "gold": 30,
        "silver": 90,
        "bronze": 400,
      },
    },
  },
};

const Map<String, dynamic> _trophyTitles = <String, dynamic>{
  "trophyTitles": <dynamic>[
    <String, dynamic>{
      "npServiceName": "trophy2",
      "npCommunicationId": "NPWR21647_00",
      "trophyTitleName": "Hades",
      "trophyTitleIconUrl":
          "https://image.api.playstation.com/trophy/hades.png",
      "trophyTitlePlatform": "PS5",
      "definedTrophies": <String, dynamic>{
        "bronze": 30,
        "silver": 13,
        "gold": 5,
        "platinum": 1,
      },
      "progress": 100,
      "earnedTrophies": <String, dynamic>{
        "bronze": 30,
        "silver": 13,
        "gold": 5,
        "platinum": 1,
      },
      "lastUpdatedDateTime": "2026-09-20T23:44:56Z",
    },
    <String, dynamic>{
      "npServiceName": "trophy",
      "npCommunicationId": "NPWR00133_00",
      "trophyTitleName": "Uncharted 2: Among Thieves™",
      "trophyTitleIconUrl": "https://image.api.playstation.com/trophy/u2.png",
      "trophyTitlePlatform": "PS3",
      "definedTrophies": <String, dynamic>{
        "bronze": 30,
        "silver": 13,
        "gold": 4,
        "platinum": 1,
      },
      "progress": 37,
      "earnedTrophies": <String, dynamic>{
        "bronze": 14,
        "silver": 3,
        "gold": 0,
        "platinum": 0,
      },
      "lastUpdatedDateTime": "2012-03-02T10:00:00Z",
    },
  ],
  "totalItemCount": 2,
};

const Map<String, dynamic> _playedGames = <String, dynamic>{
  "titles": <dynamic>[
    // Hades em PS5 e PS4: mesmo conceito, vira um jogo só.
    <String, dynamic>{
      "titleId": "PPSA01521_00",
      "name": "Hades",
      "localizedName": "Hades",
      "imageUrl": "https://image.api.playstation.com/vulcan/hades-ps5.png",
      "category": "ps5_native_game",
      "concept": <String, dynamic>{"id": 10002694},
      "lastPlayedDateTime": "2026-10-20T22:00:00Z",
      "playDuration": "PT40H30M10S",
    },
    <String, dynamic>{
      "titleId": "CUSA25260_00",
      "name": "Hades",
      "localizedName": "Hades",
      "imageUrl": "https://image.api.playstation.com/vulcan/hades-ps4.png",
      "category": "ps4_game",
      "concept": <String, dynamic>{"id": 10002694},
      "lastPlayedDateTime": "2026-08-01T20:00:00Z",
      "playDuration": "PT2H0M0S",
    },
    // Jogado sem troféus importados (ex.: app de streaming de jogo).
    <String, dynamic>{
      "titleId": "PPSA07950_00",
      "name": "ASTRO BOT",
      "localizedName": "ASTRO BOT",
      "imageUrl": "https://image.api.playstation.com/vulcan/astro.png",
      "category": "ps5_native_game",
      "concept": <String, dynamic>{"id": 10009620},
      "lastPlayedDateTime": "2026-09-01T18:00:00Z",
      "playDuration": "PT15H5M0S",
    },
  ],
  "totalItemCount": 3,
};

const PsnException _private = PsnException(
  "A privacidade dessa conta da PSN não deixa ver os jogos.",
  kind: PsnErrorKind.private,
);

void main() {
  group("parsePsnOnlineId", () {
    test("aceita o ID puro, com @ e o link do PSNProfiles", () {
      expect(parsePsnOnlineId("  Kratos_BR "), "Kratos_BR");
      expect(parsePsnOnlineId("@Kratos_BR"), "Kratos_BR");
      expect(
        parsePsnOnlineId("https://psnprofiles.com/Kratos_BR"),
        "Kratos_BR",
      );
    });

    test("recusa vazio e formatos impossíveis na PSN", () {
      expect(() => parsePsnOnlineId(""), throwsFormatException);
      expect(() => parsePsnOnlineId("ab"), throwsFormatException);
      expect(() => parsePsnOnlineId("1comecaComNumero"), throwsFormatException);
      expect(() => parsePsnOnlineId("tem espaço"), throwsFormatException);
    });
  });

  test("parsePsnDuration converte ISO 8601 em minutos", () {
    expect(parsePsnDuration("PT40H30M10S"), 40 * 60 + 30);
    expect(parsePsnDuration("PT2H"), 120);
    expect(parsePsnDuration("PT45S"), 1);
    expect(parsePsnDuration(null), 0);
  });

  group("Game.matchesTitle", () {
    const Game hollow = Game(
      id: "hollow-knight",
      title: "Hollow Knight",
      platform: "PC",
      genre: "Metroidvania",
      emoji: "🐞",
      synopsis: "",
    );

    test("ignora caixa, símbolos e apóstrofos diferentes", () {
      expect(Game.matchKey("ELDEN RING™"), Game.matchKey("Elden Ring"));
      expect(
        Game.matchKey("Marvel’s Spider-Man 2"),
        Game.matchKey("Marvel's Spider-Man 2"),
      );
      expect(Game.matchKey("God of War PS4"), Game.matchKey("God of War"));
    });

    test("aceita sufixo de edição, mas não outro jogo da série", () {
      expect(hollow.matchesTitle("Hollow Knight: Voidheart Edition"), isTrue);
      expect(hollow.matchesTitle("Hollow Knight: Silksong"), isFalse);
    });

    // Nomes tirados de uma conta PSN real: a mesma Sony escreve o mesmo
    // jogo de jeitos diferentes no histórico e na lista de troféus.
    test("ignora marcações de plataforma e o sufixo Trophies", () {
      expect(
        Game.matchKey("Grand Theft Auto V (PlayStation®5)"),
        Game.matchKey("Grand Theft Auto V"),
      );
      expect(
        Game.matchKey("It Takes Two  PS4™ & PS5™"),
        Game.matchKey("It Takes Two"),
      );
      expect(
        Game.matchKey("EA SPORTS FC™ 25 Trophies"),
        Game.matchKey("EA SPORTS FC™ 25"),
      );
      expect(
        Game.sameKey(
          Game.matchKey("Minecraft"),
          Game.matchKey("Minecraft: PlayStation®5 Edition"),
        ),
        isTrue,
      );
      expect(
        Game.sameKey(
          Game.matchKey("Marvel's Spider-Man"),
          Game.matchKey("Marvel's Spider-Man 2"),
        ),
        isFalse,
      );
    });
  });

  test("cleanPsnTitle tira as marcações da loja do nome exibido", () {
    expect(
      cleanPsnTitle("Grand Theft Auto V (PlayStation®5)"),
      "Grand Theft Auto V",
    );
    expect(cleanPsnTitle("It Takes Two  PS4™ & PS5™"), "It Takes Two");
    expect(cleanPsnTitle("ELDEN RING™"), "ELDEN RING");
    expect(
      cleanPsnTitle("Minecraft: PlayStation®4 Edition"),
      "Minecraft: PlayStation4 Edition",
    );
  });

  test("mesmo jogo com listas de troféus de PS4 e PS5 vira um só", () {
    Map<String, dynamic> trophyList(
      String id,
      String platform,
      int progress,
      int platinum,
    ) => <String, dynamic>{
      "npCommunicationId": id,
      "trophyTitleName": "Ghost of Tsushima",
      "trophyTitlePlatform": platform,
      "definedTrophies": <String, dynamic>{
        "bronze": 30,
        "silver": 10,
        "gold": 5,
        "platinum": 1,
      },
      "progress": progress,
      "earnedTrophies": <String, dynamic>{
        "bronze": 20,
        "silver": 5,
        "gold": 2,
        "platinum": platinum,
      },
      "lastUpdatedDateTime": "2026-01-01T10:00:00Z",
    };

    final List<PsnOwnedGame> games = mergePsnGames(
      trophyTitles: <Map<String, dynamic>>[
        trophyList("NPWR21000_00", "PS5,PSPC", 11, 0),
        trophyList("NPWR19000_00", "PS4", 100, 1),
      ],
      playedGames: <Map<String, dynamic>>[
        <String, dynamic>{
          "titleId": "PPSA01784_00",
          "name": "Ghost of Tsushima",
          "category": "ps5_native_game",
          "concept": <String, dynamic>{"id": 10000977},
          "playDuration": "PT91H",
        },
      ],
    );

    expect(games, hasLength(1));
    final PsnOwnedGame ghost = games.single;
    // Vale a lista platinada (PS4), mesmo o PS5 sendo a mais recente.
    expect(ghost.isPlatinum, isTrue);
    expect(ghost.progress, 100);
    expect(ghost.consoles, "PS5,PS4");
    expect(ghost.playtimeMinutes, 91 * 60);
  });

  group("RemotePsnLibraryService", () {
    test(
      "junta troféus e histórico, soma PS4 + PS5 e marca a platina",
      () async {
        final FakePsnApi api = FakePsnApi(<String, Object>{
          PsnActions.profile: _profile,
          PsnActions.trophyTitles: _trophyTitles,
          PsnActions.playedGames: _playedGames,
        });
        final PsnLibrary library = await RemotePsnLibraryService(
          api,
        ).loadLibrary("@Kratos_BR");

        expect(library.profile.onlineId, "Kratos_BR");
        expect(library.profile.trophyLevel, 233);
        expect(library.profile.avatarUrl, startsWith("https://"));
        expect(library.games, hasLength(3));

        final PsnOwnedGame hades = library.games.firstWhere(
          (g) => g.name == "Hades",
        );
        expect(hades.id, "10002694");
        expect(hades.playtimeMinutes, 42 * 60 + 30);
        expect(hades.consoles, "PS5,PS4");
        expect(hades.lastPlayed, DateTime.utc(2026, 10, 20, 22).toLocal());
        expect(hades.isPlatinum, isTrue);
        expect(hades.achievementsUnlocked, 49);
        expect(hades.achievementRatio, 1.0);

        // Só no histórico: tem tempo de jogo, mas nenhum troféu importado.
        final PsnOwnedGame astro = library.games.firstWhere(
          (g) => g.name == "ASTRO BOT",
        );
        expect(astro.playtimeMinutes, 15 * 60 + 5);
        expect(astro.hasAchievements, isFalse);

        // Só nos troféus (PS3): sem tempo de jogo, com progresso.
        final PsnOwnedGame uncharted = library.games.firstWhere(
          (g) => g.id == "NPWR00133_00",
        );
        expect(uncharted.name, "Uncharted 2: Among Thieves");
        expect(uncharted.playtimeMinutes, 0);
        expect(uncharted.wasPlayed, isTrue);
        expect(uncharted.achievementRatio, closeTo(0.37, 0.001));
        expect(uncharted.isPlatinum, isFalse);

        expect(library.platinumCount, 1);
        expect(library.totalPlaytimeMinutes, 42 * 60 + 30 + 15 * 60 + 5);
      },
    );

    test("histórico privado: mostra só os troféus", () async {
      final PsnLibrary library = await RemotePsnLibraryService(
        FakePsnApi(<String, Object>{
          PsnActions.profile: _profile,
          PsnActions.trophyTitles: _trophyTitles,
          PsnActions.playedGames: _private,
        }),
      ).loadLibrary("Kratos_BR");

      expect(library.games, hasLength(2));
      expect(library.totalPlaytimeMinutes, 0);
      expect(library.platinumCount, 1);
    });

    test("troféus e histórico privados: explica a privacidade", () async {
      final RemotePsnLibraryService service = RemotePsnLibraryService(
        FakePsnApi(<String, Object>{
          PsnActions.profile: _profile,
          PsnActions.trophyTitles: _private,
          PsnActions.playedGames: _private,
        }),
      );
      await expectLater(
        service.loadLibrary("Kratos_BR"),
        throwsA(
          isA<PsnException>()
              .having((e) => e.kind, "kind", PsnErrorKind.private)
              .having((e) => e.message, "message", contains("Privacidade")),
        ),
      );
    });

    test("ID inexistente vira mensagem amigável", () async {
      final RemotePsnLibraryService service = RemotePsnLibraryService(
        FakePsnApi(<String, Object>{
          PsnActions.profile: psnErrorFrom(404, <String, dynamic>{
            "error": <String, dynamic>{
              "code": 2105356,
              "message": "User not found (user: 'ninguem_aqui')",
            },
          }),
        }),
      );
      await expectLater(
        service.loadLibrary("ninguem_aqui"),
        throwsA(
          isA<PsnException>().having(
            (e) => e.kind,
            "kind",
            PsnErrorKind.notFound,
          ),
        ),
      );
    });

    test("ID inválido nem chega a chamar a PSN", () async {
      final FakePsnApi api = FakePsnApi(<String, Object>{});
      await expectLater(
        RemotePsnLibraryService(api).loadLibrary("x"),
        throwsA(isA<PsnException>()),
      );
      expect(api.calls, isEmpty);
    });
  });

  test("psnErrorFrom reconhece privacidade pela mensagem da Sony", () {
    final PsnException error = psnErrorFrom(200, <String, dynamic>{
      "error": <String, dynamic>{
        "code": 2240526,
        "message": "Not permitted by access control",
      },
    });
    expect(error.kind, PsnErrorKind.private);
  });
}
