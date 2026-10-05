import "../models/game.dart";
import "../models/review.dart";
import "mock_catalog.dart";

/// Reviews de exemplo da comunidade (nomes do grupo + alguns usuários
/// fictícios). São usadas no modo offline e também viram o seed do banco
/// (`supabase/seed.sql`, gerado por `dart run tool/generate_seed.dart`).
///
/// Cobrem casos variados de propósito: jogo com muitas reviews (Hades),
/// jogo sem nenhuma (Unpacking), notas baixas e divergentes (Counter-Strike
/// 2, Cyberpunk 2077), review só com nota, sem texto (Balatro), e textos
/// curtos e longos.
List<Review> buildMockReviews() {
  int counter = 0;

  Review r(
    String gameId,
    String author,
    int rating,
    String date,
    String comment,
  ) {
    final Game game = kMockCatalog.firstWhere((g) => g.id == gameId);
    counter++;
    return Review(
      id: "seed-${counter.toString().padLeft(2, "0")}",
      gameId: game.id,
      gameTitle: game.title,
      authorName: author,
      rating: rating,
      comment: comment,
      createdAt: DateTime.parse(date),
    );
  }

  return <Review>[
    r(
      "hollow-knight",
      "Lucas",
      5,
      "2026-05-04T21:10:00",
      "Trilha sonora e level design impecáveis. Um dos melhores do gênero.",
    ),
    r(
      "hollow-knight",
      "Carlos",
      4,
      "2026-05-11T19:42:00",
      "Difícil, mas justo. Só acho o mapa confuso no começo.",
    ),
    r(
      "hollow-knight",
      "Bia",
      5,
      "2026-06-20T23:05:00",
      "Platinei depois de 60 horas e ainda quero mais. O Caminho da Dor quase me quebrou.",
    ),
    r(
      "hollow-knight",
      "Rafa",
      3,
      "2026-08-02T14:30:00",
      "Bonito demais, mas o backtracking cansa. Larguei no Palácio Branco e voltei meses depois. Entendo o hype, só não é pra mim.",
    ),
    r(
      "hollow-knight-silksong",
      "Leonardo",
      5,
      "2026-09-12T22:18:00",
      "Valeu cada ano de espera. Hornet é muito mais ágil que o Cavaleiro e o combate ficou viciante.",
    ),
    r(
      "hollow-knight-silksong",
      "Mateus",
      4,
      "2026-09-25T20:01:00",
      "Lindo e desafiador, mas alguns chefes do começo já são punitivos demais.",
    ),
    r(
      "stardew-valley",
      "Felipe",
      5,
      "2026-05-02T10:15:00",
      "Vicia igual jogo nenhum. Já são 3 fazendas diferentes.",
    ),
    r(
      "stardew-valley",
      "Ju",
      5,
      "2026-06-08T16:47:00",
      "Joguei em coop com minha irmã e virou ritual de domingo.",
    ),
    r(
      "stardew-valley",
      "Arthur",
      4,
      "2026-07-19T11:20:00",
      "Relaxante, mas o primeiro inverno é meio parado.",
    ),
    r(
      "hades",
      "Leonardo",
      5,
      "2026-05-06T18:00:00",
      "Cada morte conta uma história nova. Combate extremamente satisfatório.",
    ),
    r(
      "hades",
      "Arthur",
      5,
      "2026-05-15T21:33:00",
      "Melhor roguelike que já joguei, sem exagero.",
    ),
    r(
      "hades",
      "Guilherme",
      5,
      "2026-06-01T13:12:00",
      "A dublagem e a trilha são absurdas. Zerei, platinei e ainda volto pra fazer Heat 32.",
    ),
    r(
      "hades",
      "Nanda",
      4,
      "2026-07-03T09:40:00",
      "Muito bom, só achei a parte final repetitiva depois da vigésima run.",
    ),
    r(
      "hades",
      "Rafa",
      5,
      "2026-08-14T22:51:00",
      "Até quem não curte roguelike se apaixona. Supergiant não erra.",
    ),
    r(
      "hades",
      "Mateus",
      5,
      "2026-09-30T19:05:00",
      "Jogo perfeito pra sessões curtas. Zagreus é carismático demais.",
    ),
    r(
      "hades-2",
      "Felipe",
      4,
      "2026-09-03T23:44:00",
      "Melinoë tem um kit muito mais variado. Ainda prefiro a história do primeiro.",
    ),
    r(
      "balatro",
      "Carlos",
      5,
      "2026-06-11T01:12:00",
      "Era só pra jogar 10 minutos. Eram 4 da manhã.",
    ),
    r(
      "balatro",
      "Guilherme",
      4,
      "2026-07-22T17:30:00",
      "Matemática virou entretenimento. Quem diria.",
    ),
    r("balatro", "Bia", 5, "2026-08-28T20:20:00", ""),
    r(
      "portal-2",
      "Lucas",
      5,
      "2026-05-20T15:00:00",
      "Roteiro hilário, puzzles geniais e o coop com amigo é obrigatório.",
    ),
    r(
      "portal-2",
      "Nanda",
      5,
      "2026-06-29T18:10:00",
      "Wheatley é o melhor personagem da Valve. Fim de papo.",
    ),
    r(
      "celeste",
      "Guilherme",
      4,
      "2026-05-28T20:45:00",
      "Controles perfeitos, mas os capítulos finais são punitivos demais pra mim.",
    ),
    r(
      "celeste",
      "Ju",
      5,
      "2026-07-12T21:15:00",
      "Um jogo sobre ansiedade que me ajudou a entender a minha. Chorei no capítulo 6.",
    ),
    r(
      "elden-ring",
      "Mateus",
      5,
      "2026-05-09T23:59:00",
      "Morri 400 vezes pra Malenia e faria tudo de novo.",
    ),
    r(
      "elden-ring",
      "Carlos",
      3,
      "2026-06-17T12:00:00",
      "Mundo incrível, mas a falta de direção me fez largar no meio. Talvez eu volte.",
    ),
    r(
      "elden-ring",
      "Rafa",
      4,
      "2026-08-21T19:30:00",
      "Exploração sem igual. Só a performance no PC que deixa a desejar.",
    ),
    r(
      "baldurs-gate-3",
      "Arthur",
      5,
      "2026-06-03T22:22:00",
      "Todas as escolhas importam de verdade. Joguei 3 vezes e cada uma foi diferente.",
    ),
    r(
      "baldurs-gate-3",
      "Felipe",
      5,
      "2026-08-09T14:05:00",
      "RPG de mesa digital perfeito. Astarion é o melhor companheiro.",
    ),
    r(
      "cyberpunk-2077",
      "Leonardo",
      2,
      "2026-05-13T20:00:00",
      "Comprei no lançamento e me arrependi. Bugado demais naquela época.",
    ),
    r(
      "cyberpunk-2077",
      "Lucas",
      4,
      "2026-07-30T21:40:00",
      "Depois da versão 2.0 e do Phantom Liberty virou outro jogo. Night City é viva.",
    ),
    r(
      "cyberpunk-2077",
      "Bia",
      3,
      "2026-09-08T16:16:00",
      "História boa, gameplay ok. Esperava mais das escolhas.",
    ),
    r(
      "red-dead-redemption-2",
      "Felipe",
      5,
      "2026-06-25T23:10:00",
      "Arthur Morgan é o melhor protagonista que já existiu. Final destruidor.",
    ),
    r(
      "red-dead-redemption-2",
      "Ju",
      4,
      "2026-09-15T13:50:00",
      "Lento no início, mas impossível de esquecer. Os detalhes são de outro mundo.",
    ),
    r(
      "god-of-war",
      "Carlos",
      5,
      "2026-07-07T19:19:00",
      "A relação entre Kratos e Atreus carrega o jogo. Plano-sequência impressionante.",
    ),
    r(
      "black-myth-wukong",
      "Rafa",
      3,
      "2026-08-05T22:00:00",
      "Chefes lindos, mas as fases entre eles são vazias e com paredes invisíveis.",
    ),
    r(
      "black-myth-wukong",
      "Mateus",
      4,
      "2026-09-20T18:45:00",
      "Visual absurdo e boss fights épicas. Vale muito a pena.",
    ),
    r(
      "counter-strike-2",
      "Guilherme",
      2,
      "2026-05-24T02:30:00",
      "Muito cheater nas partidas ranqueadas. Saudades do CS:GO.",
    ),
    r(
      "counter-strike-2",
      "Lucas",
      4,
      "2026-06-14T21:00:00",
      "Ainda é o melhor FPS competitivo. Com os amigos é outra experiência.",
    ),
    r(
      "counter-strike-2",
      "Nanda",
      1,
      "2026-07-26T23:55:00",
      "Tóxico demais. Desinstalei.",
    ),
    r(
      "counter-strike-2",
      "Carlos",
      3,
      "2026-10-01T20:10:00",
      "Gunplay excelente, matchmaking ruim.",
    ),
    r(
      "zelda-tears-of-the-kingdom",
      "Ju",
      5,
      "2026-05-30T15:35:00",
      "A Ultramão é a mecânica mais criativa da década. Construí um robô que voa.",
    ),
    r(
      "zelda-tears-of-the-kingdom",
      "Arthur",
      5,
      "2026-07-16T10:10:00",
      "Superou Breath of the Wild, o que eu achava impossível.",
    ),
    r(
      "zelda-tears-of-the-kingdom",
      "Leonardo",
      4,
      "2026-10-03T21:00:00",
      "Gigante e criativo, mas reaproveita muito o mapa do anterior.",
    ),
  ];
}
