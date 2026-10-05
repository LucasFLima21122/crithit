import "package:flutter/foundation.dart";

/// Configuração do app lida em tempo de compilação via `--dart-define` ou
/// `--dart-define-from-file=config/env.json` (ver README).
///
/// Nenhuma dessas chaves é obrigatória: sem elas o app roda em **modo
/// offline**, com dados mockados em memória — o que garante que a
/// apresentação funciona mesmo sem internet.
class AppConfig {
  AppConfig._();

  /// URL do projeto Supabase (ex.: `https://abcd1234.supabase.co`).
  static const String supabaseUrl = String.fromEnvironment("SUPABASE_URL");

  /// Chave pública (publishable, `sb_publishable_...`, ou a antiga anon) do
  /// projeto Supabase. Ela é feita para ficar no cliente: quem protege os
  /// dados são as policies de RLS.
  static const String supabasePublishableKey = String.fromEnvironment(
    "SUPABASE_PUBLISHABLE_KEY",
  );

  /// Chave da Steam Web API, usada **apenas** no modo offline em desktop ou
  /// Android (chamada direta). No modo online a chave fica guardada como
  /// secret na Edge Function `steam` do Supabase e nunca vai para o app.
  static const String steamApiKey = String.fromEnvironment("STEAM_API_KEY");

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// A Steam Web API não libera CORS, então no navegador a chamada direta
  /// é bloqueada — por isso o modo direto só vale fora da web.
  static bool get canCallSteamDirectly => steamApiKey.isNotEmpty && !kIsWeb;
}
