import "package:flutter/material.dart";

import "../models/library.dart";
import "../theme/app_colors.dart";
import "hud.dart";

/// Cor e ícone de cada plataforma. As cores das plataformas só aparecem
/// nos ícones e etiquetas delas, nunca como decoração solta.
extension GamePlatformStyle on GamePlatform {
  Color get color {
    switch (this) {
      case GamePlatform.steam:
        return AppColors.steam;
      case GamePlatform.psn:
        return AppColors.playstation;
    }
  }

  IconData get icon {
    switch (this) {
      case GamePlatform.steam:
        return Icons.computer_rounded;
      case GamePlatform.psn:
        return Icons.sports_esports_rounded;
    }
  }

  /// Rótulo curto para etiquetas ("STEAM", "PSN").
  String get shortLabel {
    switch (this) {
      case GamePlatform.steam:
        return "Steam";
      case GamePlatform.psn:
        return "PSN";
    }
  }

  /// "conquistas" na Steam, "troféus" na PlayStation.
  String get achievementsLabel {
    switch (this) {
      case GamePlatform.steam:
        return "Conquistas";
      case GamePlatform.psn:
        return "Troféus";
    }
  }
}

/// Etiqueta da plataforma (ex.: sobre a capa na biblioteca misturada).
class PlatformTag extends StatelessWidget {
  const PlatformTag({super.key, required this.platform});

  final GamePlatform platform;

  @override
  Widget build(BuildContext context) {
    return HudTag(
      label: platform.shortLabel,
      icon: platform.icon,
      color: platform.color,
      background: AppColors.background.withValues(alpha: 0.85),
    );
  }
}
