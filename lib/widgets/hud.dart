import "dart:math" as math;

import "package:flutter/material.dart";

import "../theme/app_colors.dart";
import "../theme/app_theme.dart";
import "../theme/hud_shapes.dart";

/// Painel base da interface: fundo escuro, contorno fino e os cantos
/// cortados da linguagem HUD. Com [onTap], vira um botão com ripple que
/// respeita o recorte.
class HudPanel extends StatelessWidget {
  const HudPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = AppColors.surface,
    this.borderColor = AppColors.stroke,
    this.cut = 12,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double cut;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = HudShapes.outlined(cut: cut, color: borderColor);
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A "marca" vermelha inclinada que abre os títulos de seção.
class HudTick extends StatelessWidget {
  const HudTick({super.key, this.color = AppColors.primary, this.height = 14});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.skewX(-0.35),
      alignment: Alignment.center,
      child: Container(width: 5, height: height, color: color),
    );
  }
}

/// Título de seção estilo HUD: marca vermelha, rótulo em caixa alta e uma
/// linha fina até a ação opcional ("Ver tudo").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(16, 28, 8, 12),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            const HudTick(),
            const SizedBox(width: 10),
            // Largura natural do título (até 80% da linha); o fio fica com
            // o resto. Com Flexible + Expanded os dois dividiriam ao meio.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
              child: Text(
                title.toUpperCase(),
                style: hudLabelStyle(fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: AppColors.stroke)),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!))
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// Barra de progresso segmentada, como a barra de vida/XP de um jogo.
/// Usada em conquistas, distribuição de notas e no XP do perfil.
class SegmentedBar extends StatelessWidget {
  const SegmentedBar({
    super.key,
    required this.value,
    this.segments = 12,
    this.height = 8,
    this.color = AppColors.primary,
    this.trackColor = AppColors.surfaceAlt,
  });

  /// De 0 a 1.
  final double value;
  final int segments;
  final double height;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SegmentedBarPainter(
          value: value.clamp(0, 1).toDouble(),
          segments: segments,
          color: color,
          trackColor: trackColor,
        ),
      ),
    );
  }
}

class _SegmentedBarPainter extends CustomPainter {
  _SegmentedBarPainter({
    required this.value,
    required this.segments,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final int segments;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const double gap = 3;
    final double slant = size.height * 0.6;
    final double width = (size.width - gap * (segments - 1)) / segments;
    final Paint track = Paint()..color = trackColor;
    final Paint fill = Paint()..color = color;

    Path segment(double left, double w) {
      return Path()
        ..moveTo(left + slant, 0)
        ..lineTo(left + w, 0)
        ..lineTo(left + w - slant, size.height)
        ..lineTo(left, size.height)
        ..close();
    }

    final double filled = value * segments;
    for (int i = 0; i < segments; i++) {
      final double left = i * (width + gap);
      canvas.drawPath(segment(left, width), track);
      final double part = (filled - i).clamp(0, 1).toDouble();
      if (part > 0) {
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(left, 0, width * part, size.height));
        canvas.drawPath(segment(left, width), fill);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_SegmentedBarPainter old) =>
      old.value != value ||
      old.segments != segments ||
      old.color != color ||
      old.trackColor != trackColor;
}

/// Textura de listras diagonais que some para baixo, usada atrás de
/// cabeçalhos (boas-vindas, ficha do perfil) como numa tela de título.
class HudStripes extends StatelessWidget {
  const HudStripes({super.key, this.color = AppColors.primary});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: CustomPaint(painter: _StripesPainter(color)),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  _StripesPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..strokeWidth = 10;
    for (double x = -size.height; x < size.width; x += 26) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => old.color != color;
}

/// Etiqueta pequena com canto cortado (gênero, plataforma, "você").
class HudTag extends StatelessWidget {
  const HudTag({
    super.key,
    required this.label,
    this.color = AppColors.textSecondary,
    this.background = AppColors.surfaceAlt,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: background,
        shape: HudShapes.panel(cut: 5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: hudLabelStyle(fontSize: 10.5, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mostra o "acerto" por cima da tela depois de salvar uma review, como o
/// número de dano que salta num jogo. Nota 5 é um **CRITICAL HIT**.
void showCritBurst(BuildContext context, {required int rating, int? xp}) {
  final OverlayState overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) =>
        _CritBurst(rating: rating, xp: xp, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _CritBurst extends StatefulWidget {
  const _CritBurst({required this.rating, required this.onDone, this.xp});

  final int rating;
  final int? xp;
  final VoidCallback onDone;

  @override
  State<_CritBurst> createState() => _CritBurstState();
}

class _CritBurstState extends State<_CritBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool crit = widget.rating == 5;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double t = _controller.value;
          // Entra com "soco" (escala > 1), segura e sobe sumindo.
          final double pop = Curves.elasticOut.transform(
            (t / 0.35).clamp(0, 1),
          );
          final double fade = t < 0.7 ? 1 : 1 - (t - 0.7) / 0.3;
          final double rise = t < 0.6 ? 0 : (t - 0.6) * 90;
          return Opacity(
            opacity: fade.clamp(0, 1),
            // Véu escuro no centro para o texto ler bem sobre qualquer tela.
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.75,
                  colors: [
                    AppColors.background.withValues(alpha: 0.75),
                    AppColors.background.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Transform.translate(
                offset: Offset(0, -rise),
                child: Transform.rotate(
                  angle: -math.pi / 40,
                  child: Transform.scale(
                    scale: 0.4 + pop * 0.6,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            crit ? "CRITICAL HIT!" : "HIT!",
                            style:
                                hudNumberStyle(
                                  fontSize: crit ? 46 : 40,
                                  color: crit
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ).copyWith(
                                  fontStyle: FontStyle.italic,
                                  shadows: const [
                                    Shadow(color: Colors.black, blurRadius: 18),
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(3, 3),
                                    ),
                                  ],
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List<Widget>.generate(
                              widget.rating,
                              (_) => const Icon(
                                Icons.star_rounded,
                                size: 34,
                                color: AppColors.accentGold,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 12),
                                ],
                              ),
                            ),
                          ),
                          if (widget.xp != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              "+${widget.xp} XP",
                              style:
                                  hudNumberStyle(
                                    fontSize: 20,
                                    color: AppColors.success,
                                  ).copyWith(
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
