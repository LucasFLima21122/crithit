/// Representa um jogo dentro do CritHit — tanto os do catálogo curado
/// (`lib/data/mock_catalog.dart`) quanto os importados da biblioteca Steam.
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

  static String steamGameId(int appId) => "steam-$appId";

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

  /// Id do jogo na Steam, quando ele existe lá. Liga o catálogo curado à
  /// biblioteca importada e permite buscar a capa no CDN da Steam.
  final int? steamAppId;

  final String synopsis;

  bool get isSteamOnly => id.startsWith("steam-");

  /// Capa em pé (2:3) no CDN da Steam, que libera CORS — funciona na web.
  String? get steamCoverUrl => steamAppId == null
      ? null
      : "https://cdn.cloudflare.steamstatic.com/steam/apps/$steamAppId/library_600x900.jpg";

  /// Banner horizontal, que todo jogo da Steam tem (nem todo tem a capa 2:3).
  String? get steamHeaderUrl => steamAppId == null
      ? null
      : "https://cdn.cloudflare.steamstatic.com/steam/apps/$steamAppId/header.jpg";
}
