import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/game.dart";
import "../models/review.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../utils/formatters.dart";
import "../widgets/common.dart";
import "../widgets/game_cover.dart";
import "../widgets/star_rating.dart";

/// Escrever (ou editar) a avaliação de um jogo: nota de 1 a 5 estrelas e
/// crítica em texto. Ao salvar, volta para o detalhe com a mensagem de
/// sucesso como resultado da rota.
class ReviewEditorScreen extends StatefulWidget {
  const ReviewEditorScreen({super.key, required this.game, this.existing});

  final Game game;
  final Review? existing;

  @override
  State<ReviewEditorScreen> createState() => _ReviewEditorScreenState();
}

class _ReviewEditorScreenState extends State<ReviewEditorScreen> {
  static const int _maxLength = 500;

  late final TextEditingController _comment = TextEditingController(
    text: widget.existing?.comment ?? "",
  );
  late int _rating = widget.existing?.rating ?? 0;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) {
      showCritHitSnack(
        context,
        "Escolha de 1 a 5 estrelas antes de salvar.",
        error: true,
      );
      return;
    }
    setState(() => _saving = true);
    final NavigatorState navigator = Navigator.of(context);
    try {
      await context.read<AppState>().saveReview(
        game: widget.game,
        rating: _rating,
        comment: _comment.text,
      );
      navigator.pop(
        _isEditing
            ? "Review atualizada!"
            : "Review salva! Combo de bom gosto ativado.",
      );
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        showCritHitSnack(
          context,
          "Deu ruim aqui do nosso lado. Tenta de novo?",
          error: true,
        );
      }
    }
  }

  Future<void> _delete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Apagar sua review?"),
        content: const Text("A nota e o texto somem do seu perfil e do jogo."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text("Apagar"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    final NavigatorState navigator = Navigator.of(context);
    try {
      await context.read<AppState>().deleteReview(widget.existing!);
      navigator.pop("Review apagada.");
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        showCritHitSnack(
          context,
          "Deu ruim aqui do nosso lado. Tenta de novo?",
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Editar avaliação" : "Sua avaliação"),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    GameCover(game: widget.game, width: 48, borderRadius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.game.title, style: textTheme.titleMedium),
                          Text(widget.game.genre, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Center(
                  child: StarRating(
                    rating: _rating.toDouble(),
                    size: 48,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    ratingLabel(_rating),
                    style: _rating == 0
                        ? textTheme.bodySmall
                        : textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _comment,
                  maxLines: 6,
                  maxLength: _maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  style: textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText:
                        "Escreva sua crítica sobre esse jogo... (opcional — só a nota já vale)",
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Salvar avaliação"),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _saving ? null : _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text("Apagar review"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
