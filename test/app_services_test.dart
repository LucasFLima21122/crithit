import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";

import "package:crithit/services/app_services.dart";
import "package:crithit/services/auth_service.dart";
import "package:crithit/services/psn/psn_library_service.dart";
import "package:crithit/services/review_repository.dart";
import "package:crithit/services/steam/steam_library_service.dart";
import "package:crithit/state/app_state.dart";

/// A checagem que decide entre online e offline na abertura do app. Ela
/// existe porque o projeto Supabase gratuito pausa sozinho depois de dias
/// sem uso, e porque o aparelho pode abrir o app antes de a rede subir.
void main() {
  Future<bool> reachable(MockClient client) =>
      AppServices.isServerReachable(client, retryDelay: Duration.zero);

  test("servidor respondendo: modo online", () async {
    final MockClient client = MockClient((_) async => http.Response("{}", 200));
    expect(await reachable(client), isTrue);
  });

  test("projeto pausado (domínio some do DNS): modo offline", () async {
    final MockClient client = MockClient(
      (_) async => throw http.ClientException("Failed host lookup"),
    );
    expect(await reachable(client), isFalse);
  });

  test("servidor com erro 5xx: modo offline", () async {
    final MockClient client = MockClient((_) async => http.Response("", 503));
    expect(await reachable(client), isFalse);
  });

  test("rede ainda subindo: falha na 1ª tentativa e conecta na 2ª", () async {
    int calls = 0;
    final MockClient client = MockClient((_) async {
      calls++;
      if (calls == 1) throw http.ClientException("Network is unreachable");
      return http.Response("{}", 200);
    });
    expect(await reachable(client), isTrue);
    expect(calls, 2);
  });

  group("AppState.reconnect", () {
    AppServices online() => AppServices(
      mode: BackendMode.online,
      auth: LocalAuthService(),
      reviews: LocalReviewRepository(),
      steam: DemoSteamLibraryService(),
      psn: DemoPsnLibraryService(),
    );

    test("sai do modo offline quando o servidor volta", () async {
      final AppState state = AppState(
        AppServices.offline(notice: "Não deu pra conectar no servidor."),
        reconnectServices: () async => online(),
      );
      expect(state.mode, BackendMode.offline);
      expect(await state.reconnect(), isTrue);
      expect(state.mode, BackendMode.online);
      expect(state.services.notice, isNull);
    });

    test("continua offline se o servidor ainda não responde", () async {
      final AppState state = AppState(
        AppServices.offline(notice: "Não deu pra conectar no servidor."),
        reconnectServices: () async =>
            AppServices.offline(notice: "Não deu pra conectar no servidor."),
      );
      expect(await state.reconnect(), isFalse);
      expect(state.mode, BackendMode.offline);
      expect(state.reconnecting, isFalse);
    });
  });
}
