import "../models/game.dart";

/// Catálogo mockado usado no Checkpoint 4. A partir do Checkpoint 5 este
/// dado passa a alimentar a navegação completa do app; no Checkpoint 6 pode
/// ser substituído por uma fonte de dados real, sem alterar as telas.
List<Game> buildMockGames() {
  return <Game>[
    Game(
      id: "hollow-knight",
      title: "Hollow Knight",
      platform: "PC / Switch",
      genre: "Metroidvania",
      emoji: "🐞",
      coverAsset: "assets/covers/hollow-knight.jpg",
      synopsis:
          "Explore um reino subterrâneo em ruínas, enfrente criaturas corrompidas e descubra os segredos de Hallownest neste metroidvania desenhado à mão.",
      reviews: <Review>[
        const Review(
          author: "Lucas",
          rating: 5,
          comment: "Trilha sonora e level design impecáveis. Um dos melhores do gênero.",
        ),
        const Review(
          author: "Carlos",
          rating: 4,
          comment: "Difícil, mas justo. Só acho a mapa confuso no começo.",
        ),
      ],
    ),
    Game(
      id: "stardew-valley",
      title: "Stardew Valley",
      platform: "PC / Mobile / Console",
      genre: "Simulação",
      emoji: "🌾",
      coverAsset: "assets/covers/stardew-valley.jpg",
      synopsis:
          "Herde a fazenda do seu avô e construa uma vida no campo: plante, pesque, construa relações e explore as minas da cidade.",
      reviews: <Review>[
        const Review(
          author: "Felipe",
          rating: 5,
          comment: "Vicia igual jogo nenhum. Já são 3 fazendas diferentes.",
        ),
      ],
    ),
    Game(
      id: "hades",
      title: "Hades",
      platform: "PC / Switch / PlayStation",
      genre: "Roguelike",
      emoji: "🔥",
      coverAsset: "assets/covers/hades.jpg",
      synopsis:
          "Fuja do submundo grego em um roguelike de ação com narrativa que evolui a cada nova tentativa.",
      reviews: <Review>[
        const Review(
          author: "Leonardo",
          rating: 5,
          comment: "Cada morte conta uma história nova. Combate extremamente satisfatório.",
        ),
        const Review(
          author: "Arthur",
          rating: 5,
          comment: "Melhor roguelike que já joguei, sem exagero.",
        ),
      ],
    ),
    Game(
      id: "unpacking",
      title: "Unpacking",
      platform: "PC / Mobile / Console",
      genre: "Puzzle / Relax",
      emoji: "📦",
      coverAsset: "assets/covers/unpacking.jpg",
      synopsis:
          "Desembale caixas de mudança e organize os pertences de uma vida inteira em um puzzle contemplativo e cheio de sentimento.",
      reviews: <Review>[],
    ),
    Game(
      id: "celeste",
      title: "Celeste",
      platform: "PC / Switch / Console",
      genre: "Plataforma",
      emoji: "🏔️",
      coverAsset: "assets/covers/celeste.jpg",
      synopsis:
          "Ajude Madeline a escalar a Montanha Celeste em um plataforma preciso que fala sobre ansiedade e superação.",
      reviews: <Review>[
        const Review(
          author: "Guilherme",
          rating: 4,
          comment: "Controles perfeitos, mas os capítulos finais são punitivos demais pra mim.",
        ),
      ],
    ),
  ];
}
