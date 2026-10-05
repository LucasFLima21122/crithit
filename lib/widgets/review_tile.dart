import "package:flutter/material.dart";

import "../models/review.dart";
import "../theme/app_colors.dart";
import "../utils/formatters.dart";
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

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: isMine
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                              const SizedBox(width: 6),
                              Text(
                                "você",
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(meta, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  StarRating(rating: review.rating.toDouble(), size: 16),
                ],
              ),
              if (review.hasComment) ...[
                const SizedBox(height: 8),
                Text(review.comment, style: textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Barras com a distribuição das notas (quantas reviews de 1 a 5 estrelas).
class RatingDistribution extends StatelessWidget {
  const RatingDistribution({super.key, required this.ratings});

  final List<int> ratings;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
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
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                child: Text("$stars", style: textTheme.bodySmall),
              ),
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: AppColors.accentGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxCount == 0 ? 0 : count / maxCount,
                    minHeight: 8,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceAlt,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                child: Text(
                  "$count",
                  style: textTheme.bodySmall,
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
