import "package:flutter/material.dart";

import "../models/review.dart";
import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "../utils/formatters.dart";
import "hud.dart";
import "star_rating.dart";

/// Uma review em formato de card.
///
/// Com [showGameTitle] o card mostra o nome do jogo no lugar do autor —
/// usado no histórico do perfil e nas "Últimas críticas".
class ReviewTile extends StatelessWidget {
  const ReviewTile({
    super.key,
    required this.review,
    this.showGameTitle = false,
    this.isMine = false,
    this.onTap,
  });

  final Review review;
  final bool showGameTitle;
  final bool isMine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String headline = showGameTitle
        ? review.gameTitle
        : review.authorName;
    final String meta = showGameTitle
        ? "${review.authorName} · ${formatRelativeDate(review.createdAt)}"
        : formatRelativeDate(review.createdAt);

    return HudPanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      borderColor: isMine
          ? AppColors.primary.withValues(alpha: 0.7)
          : AppColors.stroke,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            headline,
                            style: textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 8),
                          const HudTag(
                            label: "você",
                            color: Colors.white,
                            background: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(meta, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StarRating(rating: review.rating.toDouble(), size: 16),
            ],
          ),
          if (review.hasComment) ...[
            const SizedBox(height: 10),
            // Citação com o fio vermelho da marca à esquerda.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 2,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(review.comment, style: textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Barras segmentadas com a distribuição das notas (quantas reviews de 1 a
/// 5 estrelas), como barras de status de um personagem.
class RatingDistribution extends StatelessWidget {
  const RatingDistribution({super.key, required this.ratings});

  final List<int> ratings;

  @override
  Widget build(BuildContext context) {
    final List<int> counts = List<int>.generate(
      5,
      (i) => ratings.where((r) => r == i + 1).length,
    );
    final int maxCount = counts.fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: List<Widget>.generate(5, (i) {
        final int stars = 5 - i;
        final int count = counts[stars - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                child: Text("$stars", style: hudNumberStyle(fontSize: 13)),
              ),
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: AppColors.accentGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SegmentedBar(
                  value: maxCount == 0 ? 0 : count / maxCount,
                  segments: 16,
                  height: 9,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 22,
                child: Text(
                  "$count",
                  style: hudNumberStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
