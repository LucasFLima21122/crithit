import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:google_fonts/google_fonts.dart";

import "package:crithit/main.dart";
import "package:crithit/services/app_services.dart";

/// Testes de navegação do fluxo principal, no modo offline (dados mockados).
void main() {
  setUpAll(() {
    // Evita que o teste tente baixar fontes pela rede.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> startApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CritHitApp(services: AppServices.offline()));
    await tester.pumpAndSettle();
  }

  Future<void> enterAsGuest(WidgetTester tester) async {
    await tester.tap(find.text("Explorar como convidado"));
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    // Os serviços offline simulam a latência de rede com Future.delayed.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets("Boas-vindas mostra a marca e as opções de entrada", (
    tester,
  ) async {
    await startApp(tester);

    expect(find.text("CritHit"), findsOneWidget);
    expect(find.text("Cada jogo merece uma crítica."), findsOneWidget);
    expect(find.text("Entrar"), findsOneWidget);
    expect(find.text("Criar conta"), findsOneWidget);
    expect(find.text("Modo offline · dados de exemplo"), findsOneWidget);
  });

  testWidgets("Cadastro valida os campos e entra no app", (tester) async {
    await startApp(tester);
    await tester.tap(find.text("Criar conta"));
    await tester.pumpAndSettle();

    // Envia vazio: mostra os erros de validação.
    await tester.tap(find.widgetWithText(ElevatedButton, "Criar conta"));
    await tester.pumpAndSettle();
    expect(find.text("Informe seu e-mail."), findsOneWidget);
    expect(find.text("Mínimo de 6 caracteres."), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, "Nome de exibição"),
      "Lucas Ferrari",
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, "E-mail"),
      "lucas@crithit.app",
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, "Senha"),
      "segredo123",
    );
    await tester.tap(find.widgetWithText(ElevatedButton, "Criar conta"));
    await settle(tester);

    expect(find.text("E aí, Lucas!"), findsOneWidget);
    expect(find.text("Em alta na comunidade"), findsOneWidget);
  });

  testWidgets("Avaliar um jogo salva a review e ela aparece no perfil", (
    tester,
  ) async {
    await startApp(tester);
    await enterAsGuest(tester);

    // Unpacking é o jogo do catálogo que ainda não tem nenhuma review.
    await tester.tap(find.widgetWithText(NavigationDestination, "Buscar"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, "unpack");
    await tester.pumpAndSettle();
    await tester.tap(find.text("Unpacking"));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Ainda sem crítica nenhuma. Bora ser o primeiro a dar essa nota?",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text("Avaliar este jogo"));
    await tester.pumpAndSettle();

    // Salvar sem nota mostra o erro.
    await tester.tap(find.text("Salvar avaliação"));
    await tester.pump();
    expect(
      find.text("Escolha de 1 a 5 estrelas antes de salvar."),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.star_border_rounded).at(3));
    await tester.pump();
    expect(find.text("Ótimo"), findsOneWidget);
    await tester.enterText(find.byType(TextField), "Curto e emocionante.");
    await tester.tap(find.text("Salvar avaliação"));
    await tester.pumpAndSettle();

    expect(
      find.text("Review salva! Combo de bom gosto ativado."),
      findsOneWidget,
    );
    expect(find.text("Curto e emocionante."), findsOneWidget);
    expect(find.text("Editar avaliação"), findsOneWidget);

    // A review entra no histórico do perfil.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, "Perfil"));
    await tester.pumpAndSettle();
    expect(find.text("Suas críticas"), findsOneWidget);
    expect(find.text("Curto e emocionante."), findsOneWidget);
  });

  testWidgets("Conectar Steam importa a biblioteca com platinas", (
    tester,
  ) async {
    await startApp(tester);
    await enterAsGuest(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, "Biblioteca"));
    await tester.pumpAndSettle();
    expect(find.text("Traga sua Steam pro CritHit"), findsOneWidget);

    await tester.tap(find.text("Conectar Steam"));
    await tester.pumpAndSettle();

    // Perfil privado mostra o erro com a instrução de privacidade.
    await tester.enterText(find.byType(TextField), "perfil_privado");
    await tester.tap(find.text("Importar biblioteca"));
    await settle(tester);
    expect(
      find.textContaining("Esse perfil da Steam é privado"),
      findsOneWidget,
    );

    await tester.tap(find.text("Usar perfil de demonstração"));
    await settle(tester);

    expect(
      find.textContaining("Biblioteca importada! 16 jogos"),
      findsOneWidget,
    );
    expect(find.text("crithit_demo"), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, "Platinados"));
    await tester.pumpAndSettle();
    expect(find.text("5 jogos"), findsOneWidget);
    expect(find.text("Hades"), findsOneWidget);
    expect(find.text("Celeste"), findsOneWidget);

    // Um jogo da biblioteca abre o detalhe com as estatísticas da Steam.
    await tester.tap(find.text("Hades"));
    await tester.pumpAndSettle();
    expect(find.text("Na sua Steam"), findsOneWidget);
    expect(find.text("49/49 · 100%"), findsOneWidget);
    expect(find.text("Platinado"), findsOneWidget);
  });

  testWidgets("Busca filtra por plataforma e mostra estado vazio", (
    tester,
  ) async {
    await startApp(tester);
    await enterAsGuest(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, "Buscar"));
    await tester.pumpAndSettle();

    expect(find.text("17 jogos"), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, "Switch"));
    await tester.pumpAndSettle();
    expect(
      find.text("The Legend of Zelda: Tears of the Kingdom"),
      findsOneWidget,
    );
    expect(find.text("Counter-Strike 2"), findsNothing);

    await tester.enterText(find.byType(TextField).first, "jogo que não existe");
    await tester.pumpAndSettle();
    expect(find.text("Nenhum jogo encontrado"), findsOneWidget);

    await tester.tap(find.text("Limpar filtros"));
    await tester.pumpAndSettle();
    expect(find.text("17 jogos"), findsOneWidget);
  });
}
