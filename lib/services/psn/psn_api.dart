import "dart:convert";

import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";

/// Por que uma chamada à PSN falhou — o serviço decide o que fazer com
/// cada caso (ex.: histórico privado não impede de mostrar os troféus).
enum PsnErrorKind {
  /// Nenhuma conta com esse ID online.
  notFound,

  /// A conta existe, mas a privacidade não deixa ver esses dados.
  private,

  /// O token da PSN do servidor expirou ou é inválido.
  auth,
  other,
}

/// Erro da integração PlayStation com mensagem pronta para a interface.
class PsnException implements Exception {
  const PsnException(this.message, {this.kind = PsnErrorKind.other});

  final String message;
  final PsnErrorKind kind;

  @override
  String toString() => message;
}

/// Ações que o app pede à PSN. A Edge Function `psn` só aceita esta lista
/// (ver `supabase/functions/psn`).
class PsnActions {
  PsnActions._();

  /// Perfil pelo ID online: accountId, avatar e resumo de troféus.
  static const String profile = "profile";

  /// Todos os jogos com troféus (PS3, PS Vita, PS4 e PS5), com progresso.
  static const String trophyTitles = "trophyTitles";

  /// Histórico de jogo (PS4 e PS5): tempo jogado e última sessão.
  static const String playedGames = "playedGames";
}

/// Transporte de uma chamada à PSN. Devolve o JSON da Sony já decodificado,
/// no formato original (os testes usam respostas reais da API).
abstract class PsnApi {
  Future<Map<String, dynamic>> call(String action, Map<String, Object> params);
}

/// Monta a URL da Sony para cada ação. Igual à da Edge Function.
Uri psnActionUri(String action, Map<String, Object> params) {
  final String offset = "${params["offset"] ?? 0}";
  switch (action) {
    case PsnActions.profile:
      return Uri.https(
        "us-prof.np.community.playstation.net",
        "/userProfile/v1/users/${params["onlineId"]}/profile2",
        <String, String>{
          "fields":
              "onlineId,accountId,avatarUrls,plus,trophySummary(@default,level,progress,earnedTrophies)",
        },
      );
    case PsnActions.trophyTitles:
      return Uri.https(
        "m.np.playstation.com",
        "/api/trophy/v1/users/${params["accountId"]}/trophyTitles",
        <String, String>{"limit": "800", "offset": offset},
      );
    case PsnActions.playedGames:
      return Uri.https(
        "m.np.playstation.com",
        "/api/gamelist/v2/users/${params["accountId"]}/titles",
        <String, String>{
          "categories": "ps4_game,ps5_native_game",
          "limit": "200",
          "offset": offset,
        },
      );
  }
  throw PsnException("Ação da PSN desconhecida: $action");
}

/// Traduz um erro da Sony (status + corpo `{"error": {...}}`).
PsnException psnErrorFrom(int status, Object? body) {
  final Object? error = body is Map ? body["error"] : null;
  final String message = error is Map
      ? "${error["message"] ?? ""}".toLowerCase()
      : "";
  if (status == 404 || message.contains("not found")) {
    return const PsnException(
      "Não achei nenhuma conta da PSN com esse ID online.",
      kind: PsnErrorKind.notFound,
    );
  }
  if (status == 403 ||
      message.contains("access control") ||
      message.contains("forbidden") ||
      message.contains("privacy")) {
    return const PsnException(
      "A privacidade dessa conta da PSN não deixa ver os jogos.",
      kind: PsnErrorKind.private,
    );
  }
  if (status == 401) {
    return const PsnException(
      "O acesso à PSN expirou no servidor. Avise quem cuida do app.",
      kind: PsnErrorKind.auth,
    );
  }
  return PsnException("A PSN respondeu com erro ($status). Tenta de novo?");
}

/// Chamada direta à PSN, com o token NPSSO dentro do app. Só para teste
/// local em desktop/Android: no navegador a Sony bloqueia (CORS), e o token
/// é tão sensível quanto a senha da conta — no modo online ele fica como
/// secret na Edge Function `psn`.
class DirectPsnApi implements PsnApi {
  DirectPsnApi(this._npsso, {http.Client? client})
    : _client = client ?? http.Client();

  final String _npsso;
  final http.Client _client;
  String? _accessToken;
  DateTime _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const String _authBase =
      "https://ca.account.sony.com/api/authz/v3/oauth";

  /// Credenciais públicas do app oficial da PlayStation, as mesmas usadas
  /// pela comunidade (psn-api, PSNAWP).
  static const String _clientId = "09515159-7237-4370-9b40-3806e67c0891";
  static const String _basicAuth =
      "Basic MDk1MTUxNTktNzIzNy00MzcwLTliNDAtMzgwNmU2N2MwODkxOnVjUGprYTV0bnRCMktxc1A=";
  static const String _redirect = "com.scee.psxandroid.scecompcall://redirect";
  static const String _scope = "psn:mobile.v2.core psn:clientapp";

  Future<String> _token() async {
    final String? cached = _accessToken;
    if (cached != null && DateTime.now().isBefore(_expiresAt)) return cached;

    // 1. NPSSO -> código de autorização (vem no Location do redirect).
    final http.Request authorize =
        http.Request(
            "GET",
            Uri.parse("$_authBase/authorize").replace(
              queryParameters: <String, String>{
                "access_type": "offline",
                "client_id": _clientId,
                "redirect_uri": _redirect,
                "response_type": "code",
                "scope": _scope,
              },
            ),
          )
          ..followRedirects = false
          ..headers["Cookie"] = "npsso=$_npsso";
    final http.StreamedResponse redirect = await _client.send(authorize);
    final String location = redirect.headers["location"] ?? "";
    final String? code = RegExp(r"[?&]code=([^&]+)").firstMatch(location)?[1];
    if (code == null) {
      throw const PsnException(
        "O token NPSSO da PSN é inválido ou expirou.",
        kind: PsnErrorKind.auth,
      );
    }

    // 2. Código -> access token.
    final http.Response response = await _client.post(
      Uri.parse("$_authBase/token"),
      headers: <String, String>{"Authorization": _basicAuth},
      body: <String, String>{
        "code": code,
        "redirect_uri": _redirect,
        "grant_type": "authorization_code",
        "token_format": "jwt",
      },
    );
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String? token = json["access_token"] as String?;
    if (token == null) {
      throw const PsnException(
        "Não consegui autenticar na PSN.",
        kind: PsnErrorKind.auth,
      );
    }
    _accessToken = token;
    _expiresAt = DateTime.now().add(
      Duration(seconds: ((json["expires_in"] as num?)?.toInt() ?? 3600) - 60),
    );
    return token;
  }

  @override
  Future<Map<String, dynamic>> call(
    String action,
    Map<String, Object> params,
  ) async {
    final http.Response response;
    try {
      final String token = await _token();
      response = await _client
          .get(
            psnActionUri(action, params),
            headers: <String, String>{
              "Authorization": "Bearer $token",
              "Accept-Language": "en-US",
            },
          )
          .timeout(const Duration(seconds: 20));
    } on PsnException {
      rethrow;
    } on Exception {
      throw const PsnException(
        "Não consegui falar com a PSN. Confere a internet e tenta de novo?",
      );
    }
    final Object? body = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode != 200 || (body is Map && body["error"] != null)) {
      throw psnErrorFrom(response.statusCode, body);
    }
    return body! as Map<String, dynamic>;
  }
}

/// Chamada via Edge Function `psn` do Supabase, que guarda o token NPSSO
/// como secret e libera CORS. É o caminho do modo online e da web.
class SupabasePsnProxyApi implements PsnApi {
  SupabasePsnProxyApi(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> call(
    String action,
    Map<String, Object> params,
  ) async {
    try {
      final FunctionResponse response = await _client.functions.invoke(
        "psn",
        body: <String, dynamic>{"action": action, "params": params},
      );
      final Object? data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is String) return jsonDecode(data) as Map<String, dynamic>;
      throw const PsnException("Resposta inesperada da PSN.");
    } on FunctionException catch (error) {
      final Object? details = error.details;
      final String? message = details is Map
          ? details["error"] as String?
          : null;
      final PsnErrorKind kind = PsnErrorKind.values.firstWhere(
        (k) => details is Map && details["kind"] == k.name,
        orElse: () => PsnErrorKind.other,
      );
      throw PsnException(
        message ??
            "O servidor não conseguiu falar com a PSN (${error.status}).",
        kind: kind,
      );
    } on PsnException {
      rethrow;
    } on Exception {
      throw const PsnException(
        "Não consegui falar com o servidor. Confere a internet e tenta de novo?",
      );
    }
  }
}
