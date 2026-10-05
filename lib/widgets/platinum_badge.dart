import "package:flutter/material.dart";

import "../theme/app_colors.dart";

/// Selo de "Platinado" (100% das conquistas). Usa o Combo Green, a cor de
/// estados positivos da marca — o dourado fica reservado às estrelas.
class PlatinumBadge extends StatelessWidget {
  const PlatinumBadge({super.key, this.compact = false});

  /// Só o ícone, sem texto (para cards pequenos).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Platinado: 100% das conquistas",
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 8,
          vertical: compact ? 5 : 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.success, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 14,
              color: AppColors.success,
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                "Platinado",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
