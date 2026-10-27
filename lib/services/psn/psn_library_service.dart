import "../../data/mock_psn_library.dart";
import "../../models/game.dart";
import "../../models/psn.dart";
import "psn_api.dart";

/// Importa a conta PlayStation de um usuário: perfil, jogos, troféus e
/// tempo de jogo.
abstract class PsnLibraryService {
  /// `true` quando os dados são de demonstração (modo offline sem token).
  bool get isDemo;

  /// [input] é o ID online da PSN (ver [parsePsnOnlineId]).
  Future<PsnLibrary> loadLibrary(String input);
}

/// Lê o ID online digitado. Aceita `@nick`, com espaços nas pontas, ou o
/// link do perfil no PSNProfiles. IDs da PSN têm de 3 a 16 caracteres,
/// começam com letra e só usam letras, números, `-` e `_`.
String parsePsnOnlineId(String raw) {
  String input = raw.trim();
  final RegExpMatch? link = RegExp(
    r"psnprofiles\.com/([^/?#\s]+)",
  ).firstMatch(input);
  if (link != null) input = link.group(1)!;
  if (input.startsWith("@")) input = input.substring(1);
  if (input.isEmpty) {
    throw const FormatException("Digite seu ID online da PSN.");
  }
  if (!RegExp(r"^[A-Za-z][A-Za-z0-9_-]{2,15}$").hasMatch(input)) {
    throw const FormatException(
      "Esse não parece um ID online da PSN: de 3 a 16 caracteres, começando com letra (letras, números, - e _).",
    );
  }
  return input;
}

/// Converte a duração ISO 8601 da Sony ("PT69H1M36S") em minutos.
int parsePsnDuration(String? raw) {
  if (raw == null) return 0;
  int part(String unit) =>
      int.tryParse(RegExp("(\\d+)$unit").firstMatch(raw)?.group(1) ?? "") ?? 0;
  return part("H") * 60 + part("M") + (part("S") >= 30 ? 1 : 0);
}

class RemotePsnLibraryService implements PsnLibraryService {
  RemotePsnLibraryService(this._api);

  final PsnApi _api;

  /// Teto de páginas por lista, para uma conta enorme não travar o app
  /// (5 × 800 troféus / 5 × 200 jogos).
  static const int _maxPages = 5;

  @override
  bool get isDemo => false;

  @override
  Future<PsnLibrary> loadLibrary(String input) async {
    final String onlineId;
    try {
      onlineId = parsePsnOnlineId(input);
    } on FormatException catch (error) {
      throw PsnException(error.message);
    }

    final PsnProfile profile = await fetchProfile(onlineId);

    // As duas listas têm privacidade separada na PSN ("Troféus" e
    // "Jogos"). Se só uma estiver aberta, mostramos o que der.
    List<Map<String, dynamic>> trophies = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> played = <Map<String, dynamic>>[];
    PsnException? trophiesError;
    PsnException? playedError;
    try {
      trophies = await _fetchAll(
        PsnActions.trophyTitles,
        profile.accountId,
        "trophyTitles",
      );
    } on PsnException catch (error) {
      if (error.kind != PsnErrorKind.private) rethrow;
      trophiesError = error;
    }
    try {
      played = await _fetchAll(
        PsnActions.playedGames,
        profile.accountId,
        "titles",
      );
    } on PsnException catch (error) {
      if (error.kind != PsnErrorKind.private) rethrow;
      playedError = error;
    }
    if (trophiesError != null && playedError != null) {
      throw const PsnException(
        "Não consegui ver seus jogos. Na PSN, em Privacidade, deixe \"Troféus\" e \"Jogos\" visíveis para Qualquer pessoa.",
        kind: PsnErrorKind.private,
      );
    }

    return PsnLibrary(
      profile: profile,
      games: mergePsnGames(trophyTitles: trophies, playedGames: played),
      fetchedAt: DateTime.now(),
    );
  }

  Future<PsnProfile> fetchProfile(String onlineId) async {
    final Map<String, dynamic> json = await _api.call(
      PsnActions.profile,
      <String, Object>{"onlineId": onlineId},
    );
    final Map<String, dynamic>? raw = json["profile"] as Map<String, dynamic>?;
    if (raw == null || raw["accountId"] == null) {
      throw const PsnException(
        "Não achei nenhuma conta da PSN com esse ID online.",
        kind: PsnErrorKind.notFound,
      );
    }
    final List<dynamic> avatars =
        (raw["avatarUrls"] as List<dynamic>?) ?? <dynamic>[];
    final Map<String, dynamic>? summary =
        raw["trophySummary"] as Map<String, dynamic>?;
    return PsnProfile(
      accountId: "${raw["accountId"]}",
      onlineId: raw["onlineId"] as String? ?? onlineId,
      avatarUrl: avatars.isEmpty
          ? null
          : _https((avatars.last as Map<String, dynamic>)["avatarUrl"]),
      isPlus: raw["plus"] == 1 || raw["plus"] == true,
      trophyLevel: (summary?["level"] as num?)?.toInt(),
      earnedTrophies: PsnTrophyCounts.fromJson(
        summary?["earnedTrophies"] as Map<String, dynamic>?,
      ),
    );
  }

  /// Busca todas as páginas de uma lista paginada da Sony.
  Future<List<Map<String, dynamic>>> _fetchAll(
    String action,
    String accountId,
    String listKey,
  ) async {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    int offset = 0;
    for (int page = 0; page < _maxPages; page++) {
      final Map<String, dynamic> json = await _api.call(
        action,
        <String, Object>{"accountId": accountId, "offset": offset},
      );
      final List<dynamic> pageItems =
          (json[listKey] as List<dynamic>?) ?? <dynamic>[];
      items.addAll(pageItems.cast<Map<String, dynamic>>());
      final int total =
          (json["totalItemCount"] as num?)?.toInt() ?? items.length;
      if (pageItems.isEmpty || items.length >= total) break;
      offset = items.length;
    }
    return items;
  }
}

/// Junta a lista de troféus com o histórico de jogo num jogo só.
///
/// A Sony não usa o mesmo id nas duas listas (troféus usam
/// `npCommunicationId`, o histórico usa `titleId` e `concept`), então o
/// encontro é pelo nome normalizado ([Game.matchKey]). Duas regras vieram de
/// contas reais:
///   - versões PS4 e PS5 do mesmo jogo (mesmo `concept`) viram uma entrada
///     só, com o tempo somado;
///   - o mesmo jogo pode ter uma lista de troféus de PS4 e outra de PS5
///     (Ghost of Tsushima, Hollow Knight...). As duas ficam no mesmo jogo, e
///     vale a de maior progresso — platinou em qualquer uma, está platinado.
List<PsnOwnedGame> mergePsnGames({
  required List<Map<String, dynamic>> trophyTitles,
  required List<Map<String, dynamic>> playedGames,
}) {
  final Map<String, List<Map<String, dynamic>>> trophiesByKey =
      <String, List<Map<String, dynamic>>>{};
  for (final Map<String, dynamic> t in trophyTitles) {
    final String key = Game.matchKey("${t["trophyTitleName"] ?? ""}");
    trophiesByKey.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(t);
  }

  // Agrupa o histórico por conceito (PS4 + PS5 do mesmo jogo).
  final Map<String, List<Map<String, dynamic>>> playedByConcept =
      <String, List<Map<String, dynamic>>>{};
  for (final Map<String, dynamic> p in playedGames) {
    final Object? conceptId = (p["concept"] as Map<String, dynamic>?)?["id"];
    final String key = "${conceptId ?? p["titleId"]}";
    playedByConcept.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(p);
  }

  String nameOf(Map<String, dynamic> played) =>
      (played["localizedName"] as String?) ?? (played["name"] as String?) ?? "";

  // Encontra os troféus de cada jogo do histórico: primeiro os nomes iguais,
  // depois os que só diferem por edição ("Minecraft" e "Minecraft:
  // PlayStation®5 Edition"), para um nome parecido não roubar o exato.
  final Map<String, List<Map<String, dynamic>>> trophiesOfConcept =
      <String, List<Map<String, dynamic>>>{};
  for (final bool exact in <bool>[true, false]) {
    playedByConcept.forEach((String concept, List<Map<String, dynamic>> group) {
      if (trophiesOfConcept.containsKey(concept)) return;
      final String key = Game.matchKey(nameOf(group.first));
      final String? found = exact
          ? (trophiesByKey.containsKey(key) ? key : null)
          : trophiesByKey.keys.where((k) => Game.sameKey(k, key)).firstOrNull;
      if (found != null) {
        trophiesOfConcept[concept] = trophiesByKey.remove(found)!;
      }
    });
  }

  final List<PsnOwnedGame> games = <PsnOwnedGame>[];

  playedByConcept.forEach((String concept, List<Map<String, dynamic>> group) {
    final Map<String, dynamic> first = group.first;
    final List<Map<String, dynamic>> trophies =
        trophiesOfConcept[concept] ?? <Map<String, dynamic>>[];
    final Map<String, dynamic>? trophy = _bestTrophyList(trophies);

    int minutes = 0;
    DateTime? last;
    final Set<String> consoles = _consolesOf(trophies);
    for (final Map<String, dynamic> p in group) {
      minutes += parsePsnDuration(p["playDuration"] as String?);
      final DateTime? when = _date(p["lastPlayedDateTime"]);
      if (when != null && (last == null || when.isAfter(last))) last = when;
      consoles.add(_consoleOf(p["category"] as String?));
    }

    games.add(
      _fromTrophy(
        trophy,
        id: concept,
        name: nameOf(first),
        consoles: consoles,
        imageUrl:
            _https(first["localizedImageUrl"] ?? first["imageUrl"]) ??
            _https(trophy?["trophyTitleIconUrl"]),
        playtimeMinutes: minutes,
        lastPlayed: last ?? _lastUpdated(trophies),
      ),
    );
  });

  // Jogos só com troféus (PS3, Vita ou fora do histórico).
  trophiesByKey.forEach((String key, List<Map<String, dynamic>> trophies) {
    final Map<String, dynamic> trophy = _bestTrophyList(trophies)!;
    games.add(
      _fromTrophy(
        trophy,
        id: "${trophy["npCommunicationId"]}",
        name: "${trophy["trophyTitleName"] ?? ""}",
        consoles: _consolesOf(trophies),
        imageUrl: _https(trophy["trophyTitleIconUrl"]),
        playtimeMinutes: 0,
        lastPlayed: _lastUpdated(trophies),
      ),
    );
  });

  return games;
}

/// Tira do nome o que é marcação da loja, não do jogo: ™/®, "(PlayStation®5)"
/// e "PS4™ & PS5™" no fim. "Minecraft: PlayStation®4 Edition" fica como está,
/// porque ali a plataforma é parte do nome da edição.
String cleanPsnTitle(String name) {
  return name
      .replaceAll(RegExp(r"[™®]"), "")
      .replaceAll(
        RegExp(r"\s*\(PlayStation\s*[45]\)", caseSensitive: false),
        "",
      )
      .replaceAll(
        RegExp(r"\s*PS4\s*(?:&|and|/)\s*PS5\s*$", caseSensitive: false),
        "",
      )
      .replaceAll(RegExp(r"\s{2,}"), " ")
      .trim();
}

/// A lista de troféus que representa o jogo: a platinada, se houver; se
/// não, a de maior progresso.
Map<String, dynamic>? _bestTrophyList(List<Map<String, dynamic>> lists) {
  if (lists.isEmpty) return null;
  int score(Map<String, dynamic> t) {
    final int platinum =
        ((t["earnedTrophies"] as Map<String, dynamic>?)?["platinum"] as num?)
            ?.toInt() ??
        0;
    return (platinum > 0 ? 1000 : 0) + ((t["progress"] as num?)?.toInt() ?? 0);
  }

  return lists.reduce((a, b) => score(b) > score(a) ? b : a);
}

/// Consoles das listas de troféus. "PSPC" (a versão de PC que divide a
/// lista com o PS5) não é console PlayStation, então fica de fora.
Set<String> _consolesOf(List<Map<String, dynamic>> trophies) {
  return <String>{
    for (final Map<String, dynamic> t in trophies)
      ...("${t["trophyTitlePlatform"] ?? ""}".split(",")),
  }..removeAll(<String>{"", "PSPC"});
}

DateTime? _lastUpdated(List<Map<String, dynamic>> trophies) {
  DateTime? last;
  for (final Map<String, dynamic> t in trophies) {
    final DateTime? when = _date(t["lastUpdatedDateTime"]);
    if (when != null && (last == null || when.isAfter(last))) last = when;
  }
  return last;
}

PsnOwnedGame _fromTrophy(
  Map<String, dynamic>? trophy, {
  required String id,
  required String name,
  required Set<String> consoles,
  required String? imageUrl,
  required int playtimeMinutes,
  required DateTime? lastPlayed,
}) {
  const List<String> order = <String>["PS5", "PS4", "PS3", "PSVITA"];
  final List<String> sorted = (consoles..remove("")).toList()
    ..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
  return PsnOwnedGame(
    id: id,
    name: cleanPsnTitle(name),
    consoles: sorted.join(","),
    imageUrl: imageUrl,
    playtimeMinutes: playtimeMinutes,
    lastPlayed: lastPlayed,
    progress: (trophy?["progress"] as num?)?.toInt(),
    earned: trophy == null
        ? null
        : PsnTrophyCounts.fromJson(
            trophy["earnedTrophies"] as Map<String, dynamic>?,
          ),
    defined: trophy == null
        ? null
        : PsnTrophyCounts.fromJson(
            trophy["definedTrophies"] as Map<String, dynamic>?,
          ),
  );
}

String _consoleOf(String? category) {
  switch (category) {
    case "ps5_native_game":
      return "PS5";
    case "ps4_game":
      return "PS4";
  }
  return "";
}

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

/// A Sony ainda devolve alguns avatares em `http://`; a web bloqueia isso.
String? _https(Object? url) => url is String && url.isNotEmpty
    ? url.replaceFirst(RegExp(r"^http://"), "https://")
    : null;

/// Conta PSN de demonstração (modo offline): qualquer ID carrega o perfil
/// `crithit_demo`. Digitar "privado" simula a conta com privacidade fechada.
class DemoPsnLibraryService implements PsnLibraryService {
  @override
  bool get isDemo => true;

  @override
  Future<PsnLibrary> loadLibrary(String input) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (input.toLowerCase().contains("privado")) {
      throw const PsnException(
        "Não consegui ver seus jogos. Na PSN, em Privacidade, deixe \"Troféus\" e \"Jogos\" visíveis para Qualquer pessoa.",
        kind: PsnErrorKind.private,
      );
    }
    return PsnLibrary(
      profile: kDemoPsnProfile,
      games: buildDemoPsnGames(),
      fetchedAt: DateTime.now(),
    );
  }
}
