import "package:flutter/material.dart";

import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "../theme/hud_shapes.dart";
import "hud.dart";

export "hud.dart";

/// Estado vazio padrão: emoji num painel HUD, título, texto de apoio e ação.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: AppColors.surface,
              shape: HudShapes.outlined(cut: 16),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 16),
          Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Número grande + legenda em caixa alta, usado nas estatísticas do perfil
/// e das bibliotecas. É o "placar" da interface.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      cut: 10,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor ?? AppColors.primary),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  style: hudNumberStyle(fontSize: 22),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: hudLabelStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Avatar com o canto cortado do H do logo: foto (ex.: avatar da Steam ou
/// da PSN) ou as iniciais sobre o Crit Red.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 56,
  });

  final String initials;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
      ),
      child: Text(
        initials,
        style: hudNumberStyle(fontSize: size * 0.4, color: Colors.white),
      ),
    );
    final String? url = imageUrl;
    return ClipPath(
      clipper: ShapeBorderClipper(shape: HudShapes.notch(cut: size * 0.22)),
      child: url == null
          ? fallback
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}

/// Um passo numerado de instruções (ex.: "como achar seu perfil").
class StepItem extends StatelessWidget {
  const StepItem({super.key, required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: AppColors.surface,
              shape: HudShapes.outlined(cut: 6),
            ),
            child: Text(
              "$number",
              style: hudNumberStyle(fontSize: 13, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Mostra uma mensagem de sucesso ou erro com as cores semânticas da marca.
void showCritHitSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.danger : AppColors.success,
        content: Text(message),
      ),
    );
}
