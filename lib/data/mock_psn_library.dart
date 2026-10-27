import "../models/psn.dart";

/// Conta PSN de demonstração, usada quando o app roda sem Supabase e sem
/// token da PSN (modo offline).
const PsnProfile kDemoPsnProfile = PsnProfile(
  accountId: "1000000000000000000",
  onlineId: "crithit_demo",
  isPlus: true,
  trophyLevel: 312,
  earnedTrophies: PsnTrophyCounts(
    platinum: 6,
    gold: 58,
    silver: 171,
    bronze: 642,
  ),
);

/// Biblioteca PSN de demonstração. Cobre os casos que a tela precisa tratar:
/// platinas de verdade, jogos em andamento, backlog (nunca aberto), jogo só
/// com troféus e sem tempo de jogo (PS4 antigo), exclusivos que não estão no
/// catálogo (Astro Bot, Bloodborne) e Hades, que também está na Steam de
/// demonstração — o detalhe do jogo mostra as duas plataformas.
List<PsnOwnedGame> buildDemoPsnGames() {
  PsnOwnedGame g(
    String id,
    String name,
    String consoles,
    int minutes, {
    String? last,
    int? progress,
    PsnTrophyCounts? earned,
    PsnTrophyCounts? defined,
  }) {
    return PsnOwnedGame(
      id: id,
      name: name,
      consoles: consoles,
      playtimeMinutes: minutes,
      lastPlayed: last == null ? null : DateTime.parse(last),
      progress: progress,
      earned: earned,
      defined: defined,
    );
  }

  const PsnTrophyCounts c0 = PsnTrophyCounts();

  return <PsnOwnedGame>[
    g(
      "10001858",
      "Marvel's Spider-Man 2",
      "PS5",
      2280,
      last: "2026-10-19T21:40:00",
      progress: 100,
      earned: const PsnTrophyCounts(
        platinum: 1,
        gold: 3,
        silver: 9,
        bronze: 29,
      ),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 3,
        silver: 9,
        bronze: 29,
      ),
    ),
    g(
      "10002694",
      "Hades",
      "PS5,PS4",
      960,
      last: "2026-10-12T23:05:00",
      progress: 41,
      earned: const PsnTrophyCounts(gold: 1, silver: 6, bronze: 19),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 5,
        silver: 13,
        bronze: 30,
      ),
    ),
    g(
      "10004950",
      "ELDEN RING",
      "PS5",
      7200,
      last: "2026-10-04T01:15:00",
      progress: 72,
      earned: const PsnTrophyCounts(gold: 4, silver: 8, bronze: 20),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 6,
        silver: 11,
        bronze: 24,
      ),
    ),
    g(
      "10010554",
      "Helldivers 2",
      "PS5",
      5300,
      last: "2026-09-30T22:30:00",
      progress: 64,
      earned: const PsnTrophyCounts(gold: 2, silver: 9, bronze: 20),
      defined: const PsnTrophyCounts(gold: 4, silver: 12, bronze: 22),
    ),
    g(
      "10000977",
      "Ghost of Tsushima",
      "PS5,PS4",
      4100,
      last: "2026-09-02T20:20:00",
      progress: 100,
      earned: const PsnTrophyCounts(
        platinum: 1,
        gold: 6,
        silver: 13,
        bronze: 32,
      ),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 6,
        silver: 13,
        bronze: 32,
      ),
    ),
    g(
      "10009620",
      "Astro Bot",
      "PS5",
      900,
      last: "2026-08-15T16:00:00",
      progress: 100,
      earned: const PsnTrophyCounts(
        platinum: 1,
        gold: 4,
        silver: 12,
        bronze: 28,
      ),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 4,
        silver: 12,
        bronze: 28,
      ),
    ),
    g(
      "201930",
      "Bloodborne",
      "PS4",
      4600,
      last: "2026-07-21T00:40:00",
      progress: 87,
      earned: const PsnTrophyCounts(gold: 5, silver: 14, bronze: 19),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 6,
        silver: 16,
        bronze: 11,
      ),
    ),
    g(
      "10002560",
      "Black Myth: Wukong",
      "PS5",
      2700,
      last: "2026-06-30T19:10:00",
      progress: 45,
      earned: const PsnTrophyCounts(gold: 3, silver: 7, bronze: 12),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 8,
        silver: 20,
        bronze: 52,
      ),
    ),
    g(
      "10001398",
      "The Last of Us Part I",
      "PS5",
      1140,
      last: "2026-05-11T22:00:00",
      progress: 58,
      earned: const PsnTrophyCounts(gold: 2, silver: 4, bronze: 16),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 2,
        silver: 9,
        bronze: 45,
      ),
    ),
    g(
      "201011",
      "God of War",
      "PS4",
      3550,
      last: "2026-03-08T18:30:00",
      progress: 100,
      earned: const PsnTrophyCounts(
        platinum: 1,
        gold: 4,
        silver: 9,
        bronze: 23,
      ),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 4,
        silver: 9,
        bronze: 23,
      ),
    ),
    // Só com troféus: jogo antigo, fora do histórico de tempo de jogo.
    g(
      "NPWR10544_00",
      "Stardew Valley",
      "PS4",
      0,
      last: "2025-12-26T15:00:00",
      progress: 34,
      earned: const PsnTrophyCounts(gold: 1, silver: 3, bronze: 5),
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 4,
        silver: 9,
        bronze: 26,
      ),
    ),
    // Backlog: comprou e nunca abriu.
    g(
      "10001284",
      "Gran Turismo 7",
      "PS5",
      0,
      progress: 0,
      earned: c0,
      defined: const PsnTrophyCounts(
        platinum: 1,
        gold: 5,
        silver: 13,
        bronze: 35,
      ),
    ),
  ];
}
