/// Representa um jogo dentro do CritHit — tanto os do catálogo curado
/// (`lib/data/mock_catalog.dart`) quanto os importados das bibliotecas
/// Steam e PlayStation.
class Game {
  const Game({
    required this.id,
    required this.title,
    required this.platform,
    required this.genre,
    required this.emoji,
    required this.synopsis,
    this.developer,
    this.releaseYear,
    this.coverAsset,
    this.coverUrl,
    this.steamAppId,
  });

  /// Cria um jogo a partir de um item da biblioteca Steam que não existe no
  /// catálogo curado. O id `steam-<appid>` é o mesmo usado nas reviews.
  factory Game.fromSteam({required int appId, required String name}) {
    return Game(
      id: steamGameId(appId),
      title: name,
      platform: "PC (Steam)",
      genre: "Importado da Steam",
      emoji: "🎮",
      synopsis:
          "Jogo importado da sua biblioteca Steam. Ainda não faz parte do catálogo curado do CritHit, mas você já pode dar sua nota e escrever sua crítica.",
      steamAppId: appId,
    );
  }

  /// Cria um jogo a partir de um título da conta PSN que não existe no
  /// catálogo curado. O id `psn-<id>` é o mesmo usado nas reviews.
  factory Game.fromPsn({
    required String psnId,
    required String name,
    String consoles = "",
    String? imageUrl,
  }) {
    final String label = consoles.isEmpty
        ? "PlayStation"
        : "PlayStation (${consoles.replaceAll(",", ", ")})";
    return Game(
      id: psnGameId(psnId),
      title: name,
      platform: label,
      genre: "Importado da PSN",
      emoji: "🎮",
      synopsis:
          "Jogo importado da sua conta PlayStation. Ainda não faz parte do catálogo curado do CritHit, mas você já pode dar sua nota e escrever sua crítica.",
      coverUrl: imageUrl,
    );
  }

  static String steamGameId(int appId) => "steam-$appId";

  static String psnGameId(String psnId) => "psn-$psnId";

  /// Normaliza um título para comparar o mesmo jogo entre plataformas e
  /// entre as listas da própria Sony, que escrevem o nome de jeitos
  /// diferentes: "ELDEN RING™" e "Elden Ring", "Grand Theft Auto V
  /// (PlayStation®5)", "It Takes Two PS4™ & PS5™", "EA SPORTS FC 25 Trophies".
  static String matchKey(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r"ps4\W*(?:&|and|/)\W*ps5"), "")
        .replaceAll(RegExp(r"playstation\W*[45]|\bps[45]\b"), "")
        .replaceAll("&", "and")
        .replaceAll(RegExp(r"[^a-z0-9]"), "")
        .replaceAll(RegExp(r"trophies$"), "");
  }

  /// O que pode sobrar depois do nome base sem mudar de jogo: um nome de
  /// edição ("Hollow Knight: Voidheart Edition" continua sendo Hollow
  /// Knight; "Marvel's Spider-Man Remastered" continua sendo Spider-Man).
  static final RegExp _editionSuffix = RegExp(
    r"^[a-z0-9]*(edition|remastered|remaster|directorscut|goty|gameoftheyear)$",
  );

  /// `true` se as duas chaves ([matchKey]) são o mesmo jogo: iguais, ou uma
  /// é a outra mais um sufixo de edição.
  static bool sameKey(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final String short = a.length < b.length ? a : b;
    final String long = a.length < b.length ? b : a;
    final String rest = long.substring(short.length);
    return long.startsWith(short) && _editionSuffix.hasMatch(rest);
  }

  /// `true` se [otherTitle] é este jogo, igual ou com sufixo de edição.
  bool matchesTitle(String otherTitle) =>
      sameKey(matchKey(title), matchKey(otherTitle));

  final String id;
  final String title;
  final String platform;
  final String genre;
  final String? developer;
  final int? releaseYear;

  /// Emoji usado como "capa" quando não há imagem (ou ela falha ao carregar).
  final String emoji;

  /// Capa local (ex.: `assets/covers/hades.jpg`) — funciona sem internet.
  final String? coverAsset;

  /// Capa pela internet, para jogos importados que não têm capa local nem
  /// Steam (ex.: a arte do jogo na PSN).
  final String? coverUrl;

  /// Id do jogo na Steam, quando ele existe lá. Liga o catálogo curado à
  /// biblioteca importada e permite buscar a capa no CDN da Steam.
  final int? steamAppId;

  final String synopsis;

  /// Jogo que veio de uma biblioteca importada e não está no catálogo.
  bool get isImported => id.startsWith("steam-") || id.startsWith("psn-");

  /// Capa em pé (2:3) no CDN da Steam, que libera CORS — funciona na web.
  String? get steamCoverUrl => steamAppId == null
      ? null
      : "https://cdn.cloudflare.steamstatic.com/steam/apps/$steamAppId/library_600x900.jpg";

  /// Banner horizontal, que todo jogo da Steam tem (nem todo tem a capa 2:3).
  String? get steamHeaderUrl => steamAppId == null
      ? null
      : "https://cdn.cloudflare.steamstatic.com/steam/apps/$steamAppId/header.jpg";
}
