import "dart:convert";

import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";

/// Erro da integração Steam com mensagem pronta para a interface.
class SteamException implements Exception {
  const SteamException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Métodos da Steam Web API que o app usa. A Edge Function `steam` só
/// repassa chamadas para esta lista (ver `supabase/functions/steam`).
class SteamMethods {
  SteamMethods._();

  static const String resolveVanityUrl = "ISteamUser/ResolveVanityURL/v1";
  static const String getPlayerSummaries = "ISteamUser/GetPlayerSummaries/v2";
  static const String getOwnedGames = "IPlayerService/GetOwnedGames/v1";

  /// Conquistas desbloqueadas por jogo, em lote. (A GetAchievementsProgress
  /// parece mais direta, mas só aceita token de usuário do cliente Steam, não
  /// a chave da Web API.)
  static const String getTopAchievementsForGames =
      "IPlayerService/GetTopAchievementsForGames/v1";
}

/// Transporte de uma chamada à Steam Web API. Devolve o JSON já decodificado.
abstract class SteamApi {
  /// [params] aceita valores simples ou listas — listas viram `nome[0]`,
  /// `nome[1]`... como a Steam espera (ex.: `appids`).
  Future<Map<String, dynamic>> call(String method, Map<String, Object> params);
}

/// Monta os query params no formato da Steam Web API.
Map<String, String> encodeSteamParams(Map<String, Object> params) {
  final Map<String, String> query = <String, String>{};
  params.forEach((String key, Object value) {
    if (value is List) {
      for (int i = 0; i < value.length; i++) {
        query["$key[$i]"] = value[i].toString();
      }
    } else {
      query[key] = value.toString();
    }
  });
  return query;
}

/// Chamada direta a `api.steampowered.com`. Só funciona fora do navegador,
/// porque a Steam não libera CORS — usada no modo offline em desktop/Android.
class DirectSteamApi implements SteamApi {
  DirectSteamApi(this._apiKey, {http.Client? client})
    : _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  @override
  Future<Map<String, dynamic>> call(
    String method,
    Map<String, Object> params,
  ) async {
    final Uri uri = Uri.https(
      "api.steampowered.com",
      "/$method/",
      <String, String>{
        "key": _apiKey,
        "format": "json",
        ...encodeSteamParams(params),
      },
    );
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 20));
    } on Exception {
      throw const SteamException(
        "Não consegui falar com a Steam. Confere a internet e tenta de novo?",
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SteamException("A chave da Steam Web API é inválida.");
    }
    if (response.statusCode != 200) {
      throw SteamException(
        "A Steam respondeu com erro (${response.statusCode}). Tenta de novo daqui a pouco.",
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

/// Chamada via Edge Function `steam` do Supabase, que guarda a chave da
/// Steam como secret e devolve o JSON com CORS liberado. É o caminho usado
/// no modo online — e o único que funciona no Flutter Web.
class SupabaseSteamProxyApi implements SteamApi {
  SupabaseSteamProxyApi(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> call(
    String method,
    Map<String, Object> params,
  ) async {
    try {
      final FunctionResponse response = await _client.functions.invoke(
        "steam",
        body: <String, dynamic>{"method": method, "params": params},
      );
      final Object? data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is String) return jsonDecode(data) as Map<String, dynamic>;
      throw const SteamException("Resposta inesperada da Steam.");
    } on FunctionException catch (error) {
      final Object? details = error.details;
      final String? message = details is Map
          ? details["error"] as String?
          : null;
      throw SteamException(
        message ??
            "O servidor não conseguiu falar com a Steam (${error.status}).",
      );
    } on SteamException {
      rethrow;
    } on Exception {
      throw const SteamException(
        "Não consegui falar com o servidor. Confere a internet e tenta de novo?",
      );
    }
  }
}
