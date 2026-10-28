import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";

import "../config/app_config.dart";
import "auth_service.dart";
import "psn/psn_api.dart";
import "psn/psn_library_service.dart";
import "review_repository.dart";
import "steam/steam_api.dart";
import "steam/steam_library_service.dart";

/// Em qual "modo" o app está rodando — aparece no perfil e na tela inicial.
enum BackendMode {
  /// Supabase configurado: login, reviews e Steam reais.
  online,

  /// Sem Supabase: tudo mockado em memória (ideal pra apresentar sem rede).
  offline,
}

/// Agrupa as implementações concretas dos serviços. É o único lugar que
/// decide entre Supabase e dados mockados — as telas nunca sabem disso.
class AppServices {
  const AppServices({
    required this.mode,
    required this.auth,
    required this.reviews,
    required this.steam,
    required this.psn,
    this.notice,
  });

  /// Tudo em memória, com dados mockados. Usado nos testes e quando não há
  /// configuração do Supabase.
  factory AppServices.offline({String? notice}) {
    return AppServices(
      mode: BackendMode.offline,
      auth: LocalAuthService(),
      reviews: LocalReviewRepository(),
      steam: AppConfig.canCallSteamDirectly
          ? RemoteSteamLibraryService(DirectSteamApi(AppConfig.steamApiKey))
          : DemoSteamLibraryService(),
      psn: AppConfig.canCallPsnDirectly
          ? RemotePsnLibraryService(DirectPsnApi(AppConfig.psnNpsso))
          : DemoPsnLibraryService(),
      notice: notice,
    );
  }

  final BackendMode mode;
  final AuthService auth;
  final ReviewRepository reviews;
  final SteamLibraryService steam;
  final PsnLibraryService psn;

  /// Aviso opcional para mostrar ao usuário (ex.: "não conectou no Supabase").
  final String? notice;

  /// Inicializa o Supabase se houver configuração; se falhar, cai para o
  /// modo offline em vez de travar o app na apresentação.
  static Future<AppServices> create({http.Client? client}) async {
    if (!AppConfig.hasSupabase) return AppServices.offline();

    // O `Supabase.initialize` não fala com o servidor, então "dá certo"
    // mesmo com ele fora do ar (sem internet, projeto pausado...). Por isso
    // testamos antes se o servidor responde.
    if (!await isServerReachable(client ?? http.Client())) {
      return AppServices.offline(
        notice:
            "Não deu pra conectar no servidor. Rodando com dados de exemplo.",
      );
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
      );
      final SupabaseClient client = Supabase.instance.client;
      return AppServices(
        mode: BackendMode.online,
        auth: SupabaseAuthService(client),
        reviews: SupabaseReviewRepository(client),
        steam: RemoteSteamLibraryService(SupabaseSteamProxyApi(client)),
        psn: RemotePsnLibraryService(SupabasePsnProxyApi(client)),
      );
    } on Object catch (error) {
      debugPrint("Falha ao iniciar o Supabase: $error");
      return AppServices.offline(
        notice:
            "Não deu pra conectar no servidor. Rodando com dados de exemplo.",
      );
    }
  }

  /// `true` se o Supabase Auth responde. Tenta mais de uma vez porque, logo
  /// depois de ligar, o celular ou o emulador pode ainda estar subindo a
  /// rede — sem isso o app abria offline à toa.
  static Future<bool> isServerReachable(
    http.Client client, {
    int attempts = 2,
    Duration timeout = const Duration(seconds: 8),
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        final http.Response response = await client
            .get(
              Uri.parse("${AppConfig.supabaseUrl}/auth/v1/health"),
              headers: <String, String>{
                "apikey": AppConfig.supabasePublishableKey,
              },
            )
            .timeout(timeout);
        if (response.statusCode < 500) return true;
      } on Object catch (error) {
        debugPrint("Supabase não respondeu (tentativa $attempt): $error");
      }
      if (attempt < attempts) await Future<void>.delayed(retryDelay);
    }
    return false;
  }
}
