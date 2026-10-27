import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";

import "package:crithit/services/app_services.dart";

/// A checagem que decide entre online e offline na abertura do app. Ela
/// existe porque o projeto Supabase gratuito pausa sozinho depois de dias
/// sem uso — e aí o app precisa cair para os dados de exemplo.
void main() {
  test("servidor respondendo: modo online", () async {
    final MockClient client = MockClient((_) async => http.Response("{}", 200));
    expect(await AppServices.isServerReachable(client), isTrue);
  });

  test("projeto pausado (domínio some do DNS): modo offline", () async {
    final MockClient client = MockClient(
      (_) async => throw http.ClientException("Failed host lookup"),
    );
    expect(await AppServices.isServerReachable(client), isFalse);
  });

  test("servidor com erro 5xx: modo offline", () async {
    final MockClient client = MockClient((_) async => http.Response("", 503));
    expect(await AppServices.isServerReachable(client), isFalse);
  });
}
