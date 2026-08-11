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
    case 'aguardando_aceite':
      return (
        label: 'Aguardando o motorista',
        color: s.warning,
        icon: Icons.hourglass_top,
      );
    case 'acoplar_carreta':
      return (
        label: 'Acoplar carreta',
        color: s.brand,
        icon: Icons.rv_hookup_outlined,
      );
    case 'em_transito':
      return (label: 'Em trânsito', color: s.info, icon: Icons.local_shipping_outlined);
    case 'finalizado':
      return (label: 'Concluída', color: s.success, icon: Icons.check_circle_outline);
    default:
      return (
        label: status ?? '—',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        icon: Icons.help_outline,
      );
  }
}

/// Instrução em linguagem direta para o motorista, conforme a etapa da viagem.
String instrucaoViagem(String? status) {
  switch (status) {
    case 'aguardando_aceite':
      return 'A empresa escolheu você! Confirme para começar.';
    case 'acoplar_carreta':
      return 'Vá até o local abaixo e acople a carreta.';
    case 'em_transito':
      return 'Siga viagem até o destino e entregue a carga.';
    case 'finalizado':
      return 'Entrega concluída. Obrigado!';
    default:
      return '';
  }
}

/// Etapas da viagem na ordem, para desenhar a linha do tempo do motorista.
const etapasViagem = <({String status, String titulo, IconData icone})>[
  (
    status: 'acoplar_carreta',
    titulo: 'Acoplar carreta',
    icone: Icons.rv_hookup_outlined
  ),
  (
    status: 'em_transito',
    titulo: 'Em trânsito',
    icone: Icons.local_shipping_outlined
  ),
  (
    status: 'finalizado',
    titulo: 'Concluída',
    icone: Icons.check_circle_outline
  ),
];

/// Posição da carga na linha do tempo (-1 = ainda não aceitou).
int indiceEtapa(String? status) {
  switch (status) {
    case 'acoplar_carreta':
      return 0;
    case 'em_transito':
      return 1;
    case 'finalizado':
      return 2;
    default:
      return -1;
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
    case 'cancelada':
      return (
        label: 'Cancelada',
        color: s.danger,
        icon: Icons.do_not_disturb_on_outlined,
        descricao: 'Você cancelou esta viagem.',
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
