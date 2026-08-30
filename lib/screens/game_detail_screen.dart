import "package:flutter/material.dart";

import "../models/game.dart";
import "../theme/app_colors.dart";
import "../widgets/star_rating.dart";

/// Tela de detalhe de um jogo: sinopse, nota média da comunidade, reviews
/// já existentes e um formulário para o usuário dar sua própria nota
/// (1 a 5 estrelas) e escrever uma review — o coração do CritHit.
class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key, required this.game});

  final Game game;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escolha de 1 a 5 estrelas antes de salvar.")),
      );
      return;
    }

    setState(() {
      widget.game.reviews.add(
        Review(
          author: "Você",
          rating: _selectedRating,
          comment: _commentController.text.trim().isEmpty
              ? "(sem comentário)"
              : _commentController.text.trim(),
        ),
      );
      _commentController.clear();
      _selectedRating = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review salva! Combo de bom gosto ativado.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Game game = widget.game;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(game.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(game.emoji, style: const TextStyle(fontSize: 36)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(game.title, style: textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        "${game.platform} · ${game.genre}",
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StarRating(rating: game.averageRating, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            game.reviews.isEmpty
                                ? "sem notas ainda"
                                : "${game.averageRating.toStringAsFixed(1)} · ${game.reviews.length} review(s)",
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Sinopse", style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(game.synopsis, style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sua avaliação", style: textTheme.titleMedium),
                  const SizedBox(height: 10),
                  StarRating(
                    rating: _selectedRating.toDouble(),
                    size: 32,
                    onChanged: (int value) {
                      setState(() => _selectedRating = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    style: textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: "Escreva sua crítica sobre esse jogo...",
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      child: const Text("Salvar avaliação"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("Reviews da comunidade", style: textTheme.titleMedium),
            const SizedBox(height: 10),
            if (game.reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "Ainda sem crítica nenhuma. Bora ser o primeiro a dar essa nota?",
                  style: textTheme.bodySmall,
                ),
              )
            else
              ...game.reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(review.author, style: textTheme.titleMedium),
                            StarRating(rating: review.rating.toDouble(), size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(review.comment, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
