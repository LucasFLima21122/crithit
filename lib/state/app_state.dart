import "package:flutter/foundation.dart";

import "../data/mock_catalog.dart";
import "../models/app_user.dart";
import "../models/game.dart";
import "../models/library.dart";
import "../models/psn.dart";
import "../models/review.dart";
import "../models/steam.dart";
import "../services/app_services.dart";
import "../services/psn/psn_api.dart";
import "../services/steam/steam_api.dart";
import "../utils/player_level.dart";

/// Estado compartilhado do app: sessão, reviews e bibliotecas importadas
/// (Steam e PlayStation).
///
/// As telas leem daqui com `context.watch<AppState>()` e chamam os métodos
/// para agir; toda mudança chama [notifyListeners] e a interface se refaz.
class AppState extends ChangeNotifier {
  AppState(AppServices services, {this.reconnectServices = AppServices.create})
    : _services = services;

  AppServices _services;
  AppServices get services => _services;

  /// Como montar os serviços de novo ao tentar reconectar (troca nos testes).
  final Future<AppServices> Function() reconnectServices;

  BackendMode get mode => services.mode;

  bool _reconnecting = false;
  bool get reconnecting => _reconnecting;

  /// Tenta sair do modo offline sem fechar o app (ex.: o celular estava sem
  /// rede ao abrir). Só vale antes do login, na tela de boas-vindas.
  /// Devolve `true` se conseguiu ficar online.
  Future<bool> reconnect() async {
    if (mode == BackendMode.online || _reconnecting || isSignedIn) {
      return mode == BackendMode.online;
    }
    _reconnecting = true;
    notifyListeners();
    final AppServices next = await reconnectServices();
    if (next.mode == BackendMode.online) {
      _services = next;
      // Quem já tinha entrado online antes volta direto para a conta.
      _user = await services.auth.restoreSession();
      if (_user != null) await _afterSignIn();
    }
    _reconnecting = false;
    notifyListeners();
    return mode == BackendMode.online;
  }

  // ---------------------------------------------------------------- sessão

  bool _initializing = true;
  bool get initializing => _initializing;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  Future<void> init() async {
    _user = await services.auth.restoreSession();
    if (_user != null) await _afterSignIn();
    _initializing = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _user = await services.auth.signIn(email: email, password: password);
    notifyListeners();
    await _afterSignIn();
  }

  Future<void> signUp(String name, String email, String password) async {
    _user = await services.auth.signUp(
      displayName: name,
      email: email,
      password: password,
    );
    notifyListeners();
    await _afterSignIn();
  }

  Future<void> signInAsGuest() async {
    _user = await services.auth.signInAsGuest();
    notifyListeners();
    await _afterSignIn();
  }

  Future<void> signOut() async {
    await services.auth.signOut();
    _user = null;
    _library = null;
    _steamError = null;
    _psnLibrary = null;
    _psnError = null;
    notifyListeners();
  }

  Future<void> _afterSignIn() async {
    await refreshReviews();
    final String? steamId = _user?.steamId;
    final String? psnOnlineId = _user?.psnOnlineId;
    await Future.wait<void>([
      if (steamId != null) connectSteam(steamId, persist: false),
      if (psnOnlineId != null) connectPsn(psnOnlineId, persist: false),
    ]);
  }

  // --------------------------------------------------------------- catálogo

  final List<Game> catalog = kMockCatalog;

  /// Catálogo + jogos das bibliotecas importadas que não estão no catálogo.
  List<Game> get allGames {
    final List<Game> games = List<Game>.of(catalog);
    final Set<String> ids = games.map((g) => g.id).toSet();
    for (final OwnedGame owned in ownedGames) {
      final Game game = gameForOwned(owned);
      if (ids.add(game.id)) games.add(game);
    }
    return games;
  }

  Game? gameById(String id) {
    for (final Game game in allGames) {
      if (game.id == id) return game;
    }
    return null;
  }

  /// O jogo correspondente a um item da biblioteca Steam: o do catálogo
  /// (para compartilhar reviews da comunidade) ou um criado na hora.
  Game gameForSteam(SteamOwnedGame owned) {
    for (final Game game in catalog) {
      if (game.steamAppId == owned.appId) return game;
    }
    return Game.fromSteam(appId: owned.appId, name: owned.name);
  }

  /// O jogo correspondente a um item da PSN. A Sony não tem um id em comum
  /// com o catálogo, então o encontro é pelo nome (ver [Game.matchesTitle]).
  Game gameForPsn(PsnOwnedGame owned) {
    for (final Game game in catalog) {
      if (game.matchesTitle(owned.name)) return game;
    }
    return Game.fromPsn(
      psnId: owned.id,
      name: owned.name,
      consoles: owned.consoles,
      imageUrl: owned.imageUrl,
    );
  }

  Game gameForOwned(OwnedGame owned) {
    if (owned is SteamOwnedGame) return gameForSteam(owned);
    return gameForPsn(owned as PsnOwnedGame);
  }

  // ---------------------------------------------------------------- reviews

  List<Review> _reviews = <Review>[];
  bool _loadingReviews = false;
  String? _reviewsError;

  bool get loadingReviews => _loadingReviews;
  String? get reviewsError => _reviewsError;

  /// Todas as reviews, mais recentes primeiro.
  List<Review> get reviews => _reviews;

  Future<void> refreshReviews() async {
    _loadingReviews = true;
    _reviewsError = null;
    notifyListeners();
    try {
      _reviews = await services.reviews.fetchAll();
    } on Object catch (error) {
      debugPrint("Erro ao carregar reviews: $error");
      _reviewsError = "Deu ruim aqui do nosso lado. Tenta de novo?";
    } finally {
      _loadingReviews = false;
      notifyListeners();
    }
  }

  List<Review> reviewsFor(String gameId) =>
      _reviews.where((r) => r.gameId == gameId).toList();

  double averageFor(String gameId) {
    final List<Review> list = reviewsFor(gameId);
    if (list.isEmpty) return 0;
    return list.fold<int>(0, (sum, r) => sum + r.rating) / list.length;
  }

  List<Review> get myReviews =>
      _reviews.where((r) => r.userId != null && r.userId == _user?.id).toList();

  Review? myReviewFor(String gameId) {
    for (final Review review in myReviews) {
      if (review.gameId == gameId) return review;
    }
    return null;
  }

  /// Jogos do catálogo mais bem avaliados (com pelo menos 2 reviews).
  List<Game> get topRated {
    final List<Game> rated = catalog
        .where((g) => reviewsFor(g.id).length >= 2)
        .toList();
    rated.sort((a, b) => averageFor(b.id).compareTo(averageFor(a.id)));
    return rated;
  }

  Future<void> saveReview({
    required Game game,
    required int rating,
    required String comment,
  }) async {
    final AppUser? current = _user;
    if (current == null) return;
    final Review saved = await services.reviews.save(
      userId: current.id,
      authorName: current.displayName,
      gameId: game.id,
      gameTitle: game.title,
      rating: rating,
      comment: comment.trim(),
    );
    _reviews = <Review>[saved, ..._reviews.where((r) => r.id != saved.id)];
    notifyListeners();
  }

  Future<void> deleteReview(Review review) async {
    await services.reviews.delete(review.id);
    _reviews = _reviews.where((r) => r.id != review.id).toList();
    notifyListeners();
  }

  // ------------------------------------------------- bibliotecas (geral)

  GameLibrary? libraryFor(GamePlatform platform) {
    switch (platform) {
      case GamePlatform.steam:
        return _library;
      case GamePlatform.psn:
        return _psnLibrary;
    }
  }

  bool get hasAnyLibrary => _library != null || _psnLibrary != null;

  /// Nível de crítico do usuário (ficha do perfil), somando reviews e as
  /// bibliotecas conectadas.
  PlayerLevel get playerLevel {
    final List<Review> mine = myReviews;
    final int withText = mine.where((r) => r.hasComment).length;
    return PlayerLevel.from(
      reviewsWithText: withText,
      ratingsOnly: mine.length - withText,
      platinums:
          (_library?.platinumCount ?? 0) + (_psnLibrary?.platinumCount ?? 0),
      playtimeMinutes:
          (_library?.totalPlaytimeMinutes ?? 0) +
          (_psnLibrary?.totalPlaytimeMinutes ?? 0),
    );
  }

  /// Todos os jogos importados, de todas as plataformas.
  List<OwnedGame> get ownedGames => <OwnedGame>[
    ...?_library?.games,
    ...?_psnLibrary?.games,
  ];

  /// As entradas das bibliotecas que correspondem a este jogo (ele pode
  /// estar na Steam e na PSN ao mesmo tempo).
  List<OwnedGame> ownedEntriesFor(Game game) {
    final SteamOwnedGame? steam = steamEntryFor(game);
    final PsnOwnedGame? psn = psnEntryFor(game);
    return <OwnedGame>[?steam, ?psn];
  }

  // ------------------------------------------------------------------ Steam

  SteamLibrary? _library;
  bool _loadingSteam = false;
  String? _steamError;

  SteamLibrary? get library => _library;
  bool get loadingSteam => _loadingSteam;
  String? get steamError => _steamError;
  bool get isSteamDemo => services.steam.isDemo;

  /// Importa a biblioteca Steam. Lança [SteamException] com mensagem
  /// amigável se algo der errado (e também guarda em [steamError]).
  Future<void> connectSteam(String input, {bool persist = true}) async {
    _loadingSteam = true;
    _steamError = null;
    notifyListeners();
    try {
      final SteamLibrary library = await services.steam.loadLibrary(input);
      _library = library;
      final AppUser? current = _user;
      if (persist && current != null) {
        await services.auth.updateSteamId(current.id, library.profile.steamId);
        _user = current.copyWith(steamId: library.profile.steamId);
      }
    } on SteamException catch (error) {
      _steamError = error.message;
      if (persist) rethrow;
    } on Object catch (error) {
      debugPrint("Erro ao importar biblioteca Steam: $error");
      _steamError = "Deu ruim aqui do nosso lado. Tenta de novo?";
      if (persist) throw SteamException(_steamError!);
    } finally {
      _loadingSteam = false;
      notifyListeners();
    }
  }

  Future<void> refreshSteam() async {
    final String? steamId = _library?.profile.steamId ?? _user?.steamId;
    if (steamId == null) return;
    await connectSteam(steamId, persist: false);
  }

  Future<void> disconnectSteam() async {
    final AppUser? current = _user;
    if (current != null) {
      await services.auth.updateSteamId(current.id, null);
      _user = current.copyWith(clearSteamId: true);
    }
    _library = null;
    _steamError = null;
    notifyListeners();
  }

  SteamOwnedGame? steamEntryFor(Game game) {
    final int? appId = game.steamAppId;
    if (appId == null) return null;
    for (final SteamOwnedGame owned in _library?.games ?? <SteamOwnedGame>[]) {
      if (owned.appId == appId) return owned;
    }
    return null;
  }

  /// Jogos jogados recentemente em qualquer plataforma (para "Continue de
  /// onde parou").
  List<OwnedGame> get recentlyPlayed {
    final List<OwnedGame> played =
        ownedGames.where((g) => g.lastPlayed != null && g.wasPlayed).toList()
          ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
    return played;
  }

  // ------------------------------------------------------------ PlayStation

  PsnLibrary? _psnLibrary;
  bool _loadingPsn = false;
  String? _psnError;

  PsnLibrary? get psnLibrary => _psnLibrary;
  bool get loadingPsn => _loadingPsn;
  String? get psnError => _psnError;
  bool get isPsnDemo => services.psn.isDemo;

  /// Importa a conta PSN pelo ID online. Lança [PsnException] com mensagem
  /// amigável se algo der errado (e também guarda em [psnError]).
  Future<void> connectPsn(String input, {bool persist = true}) async {
    _loadingPsn = true;
    _psnError = null;
    notifyListeners();
    try {
      final PsnLibrary library = await services.psn.loadLibrary(input);
      _psnLibrary = library;
      final AppUser? current = _user;
      if (persist && current != null) {
        await services.auth.updatePsnOnlineId(
          current.id,
          library.profile.onlineId,
        );
        _user = current.copyWith(psnOnlineId: library.profile.onlineId);
      }
    } on PsnException catch (error) {
      _psnError = error.message;
      if (persist) rethrow;
    } on Object catch (error) {
      debugPrint("Erro ao importar conta PSN: $error");
      _psnError = "Deu ruim aqui do nosso lado. Tenta de novo?";
      if (persist) throw PsnException(_psnError!);
    } finally {
      _loadingPsn = false;
      notifyListeners();
    }
  }

  Future<void> refreshPsn() async {
    final String? onlineId =
        _psnLibrary?.profile.onlineId ?? _user?.psnOnlineId;
    if (onlineId == null) return;
    await connectPsn(onlineId, persist: false);
  }

  Future<void> disconnectPsn() async {
    final AppUser? current = _user;
    if (current != null) {
      await services.auth.updatePsnOnlineId(current.id, null);
      _user = current.copyWith(clearPsnOnlineId: true);
    }
    _psnLibrary = null;
    _psnError = null;
    notifyListeners();
  }

  PsnOwnedGame? psnEntryFor(Game game) {
    for (final PsnOwnedGame owned in _psnLibrary?.games ?? <PsnOwnedGame>[]) {
      if (game.id == Game.psnGameId(owned.id) ||
          (!game.isImported && game.matchesTitle(owned.name))) {
        return owned;
      }
    }
    return null;
  }
}
