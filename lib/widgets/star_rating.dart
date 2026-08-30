import "package:flutter/material.dart";

import "../theme/app_colors.dart";

/// Widget de avaliação por estrelas (1 a 5), usado tanto para exibir uma
/// nota já dada quanto para o usuário escolher uma nota nova.
///
/// Quando [onChanged] é `null`, o widget funciona em modo apenas leitura
/// (usado para mostrar a nota média da comunidade, por exemplo).
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 28,
    this.maxRating = 5,
  });

  /// Nota atual, de 0 a [maxRating]. Aceita valores fracionários apenas
  /// para exibição (ex.: nota média 3.5); a seleção interativa sempre
  /// produz números inteiros.
  final double rating;

  /// Chamado com a nova nota (1 a [maxRating]) quando o usuário toca em
  /// uma estrela. Se for `null`, o widget vira somente leitura.
  final ValueChanged<int>? onChanged;

  final double size;
  final int maxRating;

  bool get _interactive => onChanged != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(maxRating, (int index) {
        final int starValue = index + 1;
        final IconData icon = rating >= starValue
            ? Icons.star_rounded
            : (rating > index && rating < starValue)
                ? Icons.star_half_rounded
                : Icons.star_border_rounded;

        final Widget star = Icon(
          icon,
          size: size,
          color: AppColors.accentGold,
        );

        if (!_interactive) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: star,
          );
        }

        return InkWell(
          borderRadius: BorderRadius.circular(size),
          onTap: () => onChanged!(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: star,
          ),
        );
      }),
    );
  }
}
