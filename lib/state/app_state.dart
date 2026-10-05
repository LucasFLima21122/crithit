import "package:flutter/foundation.dart";

import "../data/mock_catalog.dart";
import "../models/app_user.dart";
import "../models/game.dart";
import "../models/review.dart";
import "../models/steam.dart";
import "../services/app_services.dart";
import "../services/steam/steam_api.dart";

/// Estado compartilhado do app: sessão, reviews e biblioteca Steam.
///
/// As telas leem daqui com `context.watch<AppState>()` e chamam os métodos
/// para agir; toda mudança chama [notifyListeners] e a interface se refaz.
class AppState extends ChangeNotifier {
  AppState(this.services);

  final AppServices services;

  BackendMode get mode => services.mode;

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
    notifyListeners();
  }

  Future<void> _afterSignIn() async {
    await refreshReviews();
    final String? steamId = _user?.steamId;
    if (steamId != null) await connectSteam(steamId, persist: false);
  }

  // --------------------------------------------------------------- catálogo

  final List<Game> catalog = kMockCatalog;

  /// Catálogo + jogos da biblioteca Steam que não estão no catálogo.
  List<Game> get allGames {
    final List<Game> games = List<Game>.of(catalog);
    final Set<int> catalogAppIds = catalog
        .map((g) => g.steamAppId)
        .whereType<int>()
        .toSet();
    for (final SteamOwnedGame owned in _library?.games ?? <SteamOwnedGame>[]) {
      if (!catalogAppIds.contains(owned.appId)) {
        games.add(Game.fromSteam(appId: owned.appId, name: owned.name));
      }
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

  /// Jogos Steam jogados recentemente (para "Continue de onde parou").
  List<SteamOwnedGame> get recentlyPlayed {
    final List<SteamOwnedGame> played =
        (_library?.games ?? <SteamOwnedGame>[])
            .where((g) => g.lastPlayed != null && g.wasPlayed)
            .toList()
          ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
    return played;
  }
}
