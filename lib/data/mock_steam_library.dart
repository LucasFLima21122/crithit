import "../models/steam.dart";

/// Perfil Steam de demonstração, usado quando o app roda sem Supabase e sem
/// chave da Steam (modo offline). Permite apresentar o fluxo completo da
/// integração mesmo sem internet.
const SteamProfile kDemoSteamProfile = SteamProfile(
  steamId: "76561190000000000",
  personaName: "crithit_demo",
  profileUrl: "https://steamcommunity.com/id/crithit_demo/",
);

/// Biblioteca de demonstração. Cobre os casos que a tela precisa tratar:
/// jogos platinados (100% das conquistas), em andamento, nunca abertos
/// (backlog), sem conquistas (Counter-Strike 2) e jogos que não estão no
/// catálogo curado (Terraria, Dead Cells...).
List<SteamOwnedGame> buildDemoSteamGames() {
  SteamOwnedGame g(
    int appId,
    String name,
    int minutes, {
    String? last,
    int? unlocked,
    int? total,
  }) {
    return SteamOwnedGame(
      appId: appId,
      name: name,
      playtimeMinutes: minutes,
      lastPlayed: last == null ? null : DateTime.parse(last),
      achievementsUnlocked: unlocked,
      achievementsTotal: total,
    );
  }

  return <SteamOwnedGame>[
    g(
      1145360,
      "Hades",
      4120,
      last: "2026-09-28T22:10:00",
      unlocked: 49,
      total: 49,
    ),
    g(
      367520,
      "Hollow Knight",
      3570,
      last: "2026-08-11T20:00:00",
      unlocked: 52,
      total: 63,
    ),
    g(
      504230,
      "Celeste",
      2210,
      last: "2026-06-02T19:30:00",
      unlocked: 32,
      total: 32,
    ),
    g(
      413150,
      "Stardew Valley",
      9480,
      last: "2026-10-04T23:40:00",
      unlocked: 38,
      total: 40,
    ),
    g(
      2379780,
      "Balatro",
      6130,
      last: "2026-10-02T01:15:00",
      unlocked: 27,
      total: 35,
    ),
    g(
      1135690,
      "Unpacking",
      260,
      last: "2026-04-18T16:00:00",
      unlocked: 37,
      total: 37,
    ),
    g(
      730,
      "Counter-Strike 2",
      31250,
      last: "2026-10-05T00:30:00",
      unlocked: 0,
      total: 0,
    ),
    g(
      1245620,
      "ELDEN RING",
      7350,
      last: "2026-07-21T22:00:00",
      unlocked: 41,
      total: 42,
    ),
    g(
      620,
      "Portal 2",
      680,
      last: "2025-12-26T15:00:00",
      unlocked: 51,
      total: 51,
    ),
    g(
      1145350,
      "Hades II",
      1500,
      last: "2026-09-30T21:00:00",
      unlocked: 20,
      total: 49,
    ),
    g(
      105600,
      "Terraria",
      1820,
      last: "2026-03-10T18:20:00",
      unlocked: 40,
      total: 88,
    ),
    g(
      588650,
      "Dead Cells",
      430,
      last: "2026-01-14T21:00:00",
      unlocked: 12,
      total: 122,
    ),
    g(
      646570,
      "Slay the Spire",
      3900,
      last: "2026-05-05T23:00:00",
      unlocked: 46,
      total: 46,
    ),
    g(
      1794680,
      "Vampire Survivors",
      1200,
      last: "2026-02-22T20:45:00",
      unlocked: 150,
      total: 221,
    ),
    // Backlog: comprados na promoção e nunca abertos.
    g(292030, "The Witcher 3: Wild Hunt", 0, unlocked: 0, total: 78),
    g(1091500, "Cyberpunk 2077", 0, unlocked: 0, total: 57),
  ];
}
