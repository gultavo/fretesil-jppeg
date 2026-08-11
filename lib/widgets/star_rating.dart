import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../theme/app_theme.dart';

/// Exibição de estrelas (0-5), com meia-estrela para médias.
///
/// A cor vem do âmbar da marca definido no tema; passe [color] só para casos
/// excepcionais.
class StarRatingDisplay extends StatelessWidget {
  final double nota;
  final double size;
  final Color? color;
=======

/// Exibição de estrelas (0-5), com meia-estrela para médias.
class StarRatingDisplay extends StatelessWidget {
  final double nota;
  final double size;
  final Color color;
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05

  const StarRatingDisplay({
    super.key,
    required this.nota,
    this.size = 18,
<<<<<<< HEAD
    this.color,
=======
    this.color = const Color(0xFFE8A020),
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final cor = color ?? AppStatusColors.of(context).brand;
=======
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
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
<<<<<<< HEAD
        return Icon(icon, size: size, color: cor);
=======
        return Icon(icon, size: size, color: color);
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
      }),
    );
  }
}

/// Seletor de estrelas (0-5) para o usuário avaliar.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
<<<<<<< HEAD
  final Color? color;
=======
  final Color color;
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
<<<<<<< HEAD
    this.color,
=======
    this.color = const Color(0xFFE8A020),
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final cor = color ?? AppStatusColors.of(context).brand;
=======
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
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
<<<<<<< HEAD
            color: cor,
=======
            color: color,
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
          ),
        );
      }),
    );
  }
}
