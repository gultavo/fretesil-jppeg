import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Aparência de um estado do domínio: rótulo, cor semântica e ícone.
typedef StatusVisual = ({String label, Color color, IconData icon});

/// Estado de uma carga, com a mesma leitura nas duas home.
StatusVisual statusCarga(BuildContext context, String? status) {
  final s = AppStatusColors.of(context);
  switch (status) {
    case 'disponivel':
      return (label: 'Disponível', color: s.warning, icon: Icons.campaign_outlined);
    case 'em_transito':
      return (label: 'Em trânsito', color: s.info, icon: Icons.local_shipping_outlined);
    case 'finalizado':
      return (label: 'Concluído', color: s.success, icon: Icons.check_circle_outline);
    default:
      return (
        label: status ?? '—',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        icon: Icons.help_outline,
      );
  }
}

/// Estado de uma candidatura, com o texto explicativo mostrado ao motorista.
({String label, Color color, IconData icon, String descricao}) statusCandidatura(
  BuildContext context,
  String? status,
) {
  final s = AppStatusColors.of(context);
  switch (status) {
    case 'aceita':
      return (
        label: 'Aceita',
        color: s.success,
        icon: Icons.check_circle,
        descricao: 'Você foi aceito! Confira a aba "Minha viagem".',
      );
    case 'recusada':
      return (
        label: 'Recusada',
        color: s.danger,
        icon: Icons.cancel,
        descricao: 'A empresa escolheu outro motorista desta vez.',
      );
    default:
      return (
        label: 'Pendente',
        color: s.warning,
        icon: Icons.hourglass_top,
        descricao: 'Aguardando a empresa analisar seu perfil.',
      );
  }
}
