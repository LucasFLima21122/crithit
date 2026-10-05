import "package:flutter/foundation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../config/app_config.dart";
import "auth_service.dart";
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
      notice: notice,
    );
  }

  final BackendMode mode;
  final AuthService auth;
  final ReviewRepository reviews;
  final SteamLibraryService steam;

  /// Aviso opcional para mostrar ao usuário (ex.: "não conectou no Supabase").
  final String? notice;

  /// Inicializa o Supabase se houver configuração; se falhar, cai para o
  /// modo offline em vez de travar o app na apresentação.
  static Future<AppServices> create() async {
    if (!AppConfig.hasSupabase) return AppServices.offline();

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
      );
    } on Object catch (error) {
      debugPrint("Falha ao iniciar o Supabase: $error");
      return AppServices.offline(
        notice:
            "Não deu pra conectar no servidor. Rodando com dados de exemplo.",
      );
    }
  }
}
