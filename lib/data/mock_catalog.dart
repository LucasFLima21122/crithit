import "../models/game.dart";

/// Plataformas usadas nos filtros da busca. Os campos `platform` do
/// catálogo usam exatamente esses nomes, separados por " / ".
const List<String> kPlatforms = <String>[
  "PC",
  "PlayStation",
  "Xbox",
  "Switch",
  "Mobile",
];

/// Catálogo curado do CritHit (dados mockados, sem backend).
///
/// Os jogos foram escolhidos para cobrir casos diferentes na interface:
/// indies e AAA, exclusivo de console (sem Steam e sem capa — cai no emoji),
/// lançamentos recentes, jogos com muitas, poucas ou nenhuma review.
/// O `steamAppId` liga cada jogo à biblioteca Steam importada pelo usuário.
const List<Game> kMockCatalog = <Game>[
  Game(
    id: "hollow-knight",
    title: "Hollow Knight",
    platform: "PC / PlayStation / Xbox / Switch",
    genre: "Metroidvania",
    developer: "Team Cherry",
    releaseYear: 2017,
    emoji: "🐞",
    coverAsset: "assets/covers/hollow-knight.jpg",
    steamAppId: 367520,
    synopsis:
        "Explore um reino subterrâneo em ruínas, enfrente criaturas corrompidas e descubra os segredos de Hallownest neste metroidvania desenhado à mão.",
  ),
  Game(
    id: "hollow-knight-silksong",
    title: "Hollow Knight: Silksong",
    platform: "PC / PlayStation / Xbox / Switch",
    genre: "Metroidvania",
    developer: "Team Cherry",
    releaseYear: 2025,
    emoji: "🕷️",
    coverAsset: "assets/covers/silksong.jpg",
    steamAppId: 1030300,
    synopsis:
        "Hornet é capturada e levada a Pharloom, um reino governado pela seda e pela música. Escale até o topo da cidadela num metroidvania ainda mais rápido e acrobático.",
  ),
  Game(
    id: "stardew-valley",
    title: "Stardew Valley",
    platform: "PC / PlayStation / Xbox / Switch / Mobile",
    genre: "Simulação",
    developer: "ConcernedApe",
    releaseYear: 2016,
    emoji: "🌾",
    coverAsset: "assets/covers/stardew-valley.jpg",
    steamAppId: 413150,
    synopsis:
        "Herde a fazenda do seu avô e construa uma vida no campo: plante, pesque, construa relações e explore as minas da cidade.",
  ),
  Game(
    id: "hades",
    title: "Hades",
    platform: "PC / PlayStation / Xbox / Switch",
    genre: "Roguelike",
    developer: "Supergiant Games",
    releaseYear: 2020,
    emoji: "🔥",
    coverAsset: "assets/covers/hades.jpg",
    steamAppId: 1145360,
    synopsis:
        "Fuja do submundo grego em um roguelike de ação com narrativa que evolui a cada nova tentativa.",
  ),
  Game(
    id: "hades-2",
    title: "Hades II",
    platform: "PC / PlayStation / Xbox / Switch",
    genre: "Roguelike",
    developer: "Supergiant Games",
    releaseYear: 2025,
    emoji: "🌙",
    coverAsset: "assets/covers/hades-2.jpg",
    steamAppId: 1145350,
    synopsis:
        "Melinoë, a princesa imortal do submundo, usa bruxaria para enfrentar Cronos, o Titã do Tempo, na sequência do roguelike premiado.",
  ),
  Game(
    id: "balatro",
    title: "Balatro",
    platform: "PC / PlayStation / Xbox / Switch / Mobile",
    genre: "Roguelike",
    developer: "LocalThunk",
    releaseYear: 2024,
    emoji: "🃏",
    coverAsset: "assets/covers/balatro.jpg",
    steamAppId: 2379780,
    synopsis:
        "Um roguelike de construção de baralho inspirado no pôquer: monte mãos ilegais, combine curingas absurdos e quebre a matemática do jogo.",
  ),
  Game(
    id: "unpacking",
    title: "Unpacking",
    platform: "PC / PlayStation / Xbox / Switch / Mobile",
    genre: "Puzzle",
    developer: "Witch Beam",
    releaseYear: 2021,
    emoji: "📦",
    coverAsset: "assets/covers/unpacking.jpg",
    steamAppId: 1135690,
    synopsis:
        "Desembale caixas de mudança e organize os pertences de uma vida inteira em um puzzle contemplativo e cheio de sentimento.",
  ),
  Game(
    id: "portal-2",
    title: "Portal 2",
    platform: "PC / PlayStation / Xbox / Switch",
    genre: "Puzzle",
    developer: "Valve",
    releaseYear: 2011,
    emoji: "🌀",
    coverAsset: "assets/covers/portal-2.jpg",
    steamAppId: 620,
    synopsis:
        "Volte ao Aperture Science com a arma de portais e resolva câmaras de teste cada vez mais insanas — sozinho ou em cooperativo.",
  ),
  Game(
    id: "celeste",
    title: "Celeste",
    platform: "PC / PlayStation / Xbox / Switch",
    genre: "Plataforma",
    developer: "Maddy Makes Games",
    releaseYear: 2018,
    emoji: "🏔️",
    coverAsset: "assets/covers/celeste.jpg",
    steamAppId: 504230,
    synopsis:
        "Ajude Madeline a escalar a Montanha Celeste em um plataforma preciso que fala sobre ansiedade e superação.",
  ),
  Game(
    id: "elden-ring",
    title: "Elden Ring",
    platform: "PC / PlayStation / Xbox",
    genre: "RPG",
    developer: "FromSoftware",
    releaseYear: 2022,
    emoji: "💍",
    coverAsset: "assets/covers/elden-ring.jpg",
    steamAppId: 1245620,
    synopsis:
        "Atravesse as Terras Intermédias num mundo aberto sombrio e gigantesco, criado por Hidetaka Miyazaki com mitologia de George R. R. Martin.",
  ),
  Game(
    id: "baldurs-gate-3",
    title: "Baldur's Gate 3",
    platform: "PC / PlayStation / Xbox",
    genre: "RPG",
    developer: "Larian Studios",
    releaseYear: 2023,
    emoji: "🎲",
    coverAsset: "assets/covers/baldurs-gate-3.jpg",
    steamAppId: 1086940,
    synopsis:
        "Monte seu grupo e sobreviva a um parasita mental num RPG baseado em Dungeons & Dragons, onde quase toda escolha muda a história.",
  ),
  Game(
    id: "cyberpunk-2077",
    title: "Cyberpunk 2077",
    platform: "PC / PlayStation / Xbox",
    genre: "RPG",
    developer: "CD Projekt Red",
    releaseYear: 2020,
    emoji: "🌆",
    coverAsset: "assets/covers/cyberpunk-2077.jpg",
    steamAppId: 1091500,
    synopsis:
        "Viva como V, um mercenário em Night City, uma megalópole obcecada por poder, glamour e modificações corporais.",
  ),
  Game(
    id: "red-dead-redemption-2",
    title: "Red Dead Redemption 2",
    platform: "PC / PlayStation / Xbox",
    genre: "Ação e aventura",
    developer: "Rockstar Games",
    releaseYear: 2018,
    emoji: "🤠",
    coverAsset: "assets/covers/red-dead-redemption-2.jpg",
    steamAppId: 1174180,
    synopsis:
        "América, 1899. Arthur Morgan e a gangue Van der Linde fogem da lei num faroeste épico sobre lealdade e o fim de uma era.",
  ),
  Game(
    id: "god-of-war",
    title: "God of War",
    platform: "PC / PlayStation",
    genre: "Ação e aventura",
    developer: "Santa Monica Studio",
    releaseYear: 2018,
    emoji: "🪓",
    coverAsset: "assets/covers/god-of-war.jpg",
    steamAppId: 1593500,
    synopsis:
        "Kratos deixa a Grécia para trás e parte com o filho Atreus numa jornada pelos reinos nórdicos, entre deuses e monstros.",
  ),
  Game(
    id: "black-myth-wukong",
    title: "Black Myth: Wukong",
    platform: "PC / PlayStation",
    genre: "Ação e aventura",
    developer: "Game Science",
    releaseYear: 2024,
    emoji: "🐒",
    coverAsset: "assets/covers/black-myth-wukong.jpg",
    steamAppId: 2358720,
    synopsis:
        "Um RPG de ação inspirado em Jornada ao Oeste: como o Destinado, enfrente criaturas da mitologia chinesa em lutas contra chefes espetaculares.",
  ),
  Game(
    id: "counter-strike-2",
    title: "Counter-Strike 2",
    platform: "PC",
    genre: "FPS",
    developer: "Valve",
    releaseYear: 2023,
    emoji: "🎯",
    coverAsset: "assets/covers/counter-strike-2.jpg",
    steamAppId: 730,
    synopsis:
        "O FPS tático competitivo mais jogado do mundo: terroristas contra contraterroristas, rodada a rodada, agora na Source 2.",
  ),
  // Exclusivo de console: não existe na Steam e não tem capa local de
  // propósito — mostra o fallback em emoji funcionando.
  Game(
    id: "zelda-tears-of-the-kingdom",
    title: "The Legend of Zelda: Tears of the Kingdom",
    platform: "Switch",
    genre: "Ação e aventura",
    developer: "Nintendo",
    releaseYear: 2023,
    emoji: "🗡️",
    synopsis:
        "Link explora os céus e as profundezas de Hyrule, construindo veículos e armas improvisadas com o poder Ultramão.",
  ),
];

/// Gêneros presentes no catálogo, na ordem em que aparecem.
List<String> get kGenres {
  final List<String> genres = <String>[];
  for (final Game game in kMockCatalog) {
    if (!genres.contains(game.genre)) genres.add(game.genre);
  }
  return genres;
}
