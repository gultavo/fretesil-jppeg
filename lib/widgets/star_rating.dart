import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Exibição de estrelas (0-5), com meia-estrela para médias.
///
/// A cor vem do âmbar da marca definido no tema; passe [color] só para casos
/// excepcionais.
class StarRatingDisplay extends StatelessWidget {
  final double nota;
  final double size;
  final Color? color;

  const StarRatingDisplay({
    super.key,
    required this.nota,
    this.size = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cor = color ?? AppStatusColors.of(context).brand;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final valor = nota - i;
        IconData icon;
        if (valor >= 1) {
          icon = Icons.star_rounded;
        } else if (valor >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: size, color: cor);
      }),
    );
  }
}

/// Seletor de estrelas (0-5) para o usuário avaliar.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  final Color? color;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cor = color ?? AppStatusColors.of(context).brand;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final estrela = i + 1;
        final ativa = estrela <= value;
        return IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(),
          onPressed: () => onChanged(estrela == value ? estrela - 1 : estrela),
          icon: Icon(
            ativa ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: cor,
          ),
        );
      }),
    );
  }
}
