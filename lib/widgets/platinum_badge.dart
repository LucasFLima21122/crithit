import "package:flutter/material.dart";

import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "../theme/hud_shapes.dart";

/// Selo de platina: 100% das conquistas na Steam ou o troféu de platina na
/// PlayStation. Usa a cor "Platinum" da marca — o dourado continua
/// exclusivo das estrelas.
class PlatinumBadge extends StatelessWidget {
  const PlatinumBadge({super.key, this.compact = false});

  /// Só o ícone, sem texto (para capas e cards pequenos).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Platinado",
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppColors.background.withValues(alpha: 0.88),
          shape: HudShapes.outlined(
            cut: compact ? 5 : 7,
            color: AppColors.platinum,
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 5 : 8,
            vertical: compact ? 4 : 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 14,
                color: AppColors.platinum,
              ),
              if (!compact) ...[
                const SizedBox(width: 4),
                Text(
                  "PLATINADO",
                  style: hudLabelStyle(
                    fontSize: 10.5,
                    color: AppColors.platinum,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
