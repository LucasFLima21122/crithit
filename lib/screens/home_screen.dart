import "package:flutter/material.dart";

import "../data/mock_games.dart";
import "../models/game.dart";
import "../theme/app_colors.dart";
import "../widgets/game_card.dart";
import "game_detail_screen.dart";

/// Tela inicial do CritHit: mostra o catálogo de jogos (mockado neste
/// Checkpoint) com a nota média da comunidade e dá acesso à tela de
/// detalhe/avaliação de cada jogo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<Game> _games = buildMockGames();

  Future<void> _openGame(Game game) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GameDetailScreen(game: game),
      ),
    );
    // Ao voltar da tela de detalhe, uma nova review pode ter sido
    // adicionada — atualizamos a lista para refletir a nova média.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CritHit"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text("🎮", style: TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                "Catálogo",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                "Toque em um jogo para ver detalhes e deixar sua avaliação.",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _games.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final Game game = _games[index];
                  return GameCard(
                    game: game,
                    onTap: () => _openGame(game),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
