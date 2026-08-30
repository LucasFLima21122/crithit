import "package:flutter_test/flutter_test.dart";
import "package:google_fonts/google_fonts.dart";

import "package:crithit/main.dart";

void main() {
  setUpAll(() {
    // Evita que o teste tente baixar fontes pela rede (sem internet no
    // ambiente de CI/teste, o Flutter usa a fonte padrão da plataforma).
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets("HomeScreen mostra o título CritHit e o catálogo de jogos",
      (WidgetTester tester) async {
    await tester.pumpWidget(const CritHitApp());
    await tester.pumpAndSettle();

    expect(find.text("CritHit"), findsOneWidget);
    expect(find.text("Catálogo"), findsOneWidget);

    // O catálogo mockado deve exibir pelo menos um jogo conhecido.
    expect(find.text("Hollow Knight"), findsOneWidget);
  });

  testWidgets("Abrir um jogo mostra o formulário de avaliação por estrelas",
      (WidgetTester tester) async {
    await tester.pumpWidget(const CritHitApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text("Hollow Knight"));
    await tester.pumpAndSettle();

    expect(find.text("Sua avaliação"), findsOneWidget);
    expect(find.text("Salvar avaliação"), findsOneWidget);
  });
}
