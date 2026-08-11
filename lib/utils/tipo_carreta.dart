import 'package:flutter/material.dart';

/// Tipos de carreta aceitos pelo app.
///
/// Os códigos são exatamente os do backend (`Carga.TIPO_CARRETA_CHOICES`);
/// o rótulo e o ícone são usados nas duas telas, para a empresa escolher e
/// o motorista reconhecer de longe.
@immutable
class TipoCarreta {
  final String codigo;
  final String label;
  final IconData icone;

  const TipoCarreta(this.codigo, this.label, this.icone);

  static const todos = <TipoCarreta>[
    TipoCarreta('sider', 'Sider', Icons.view_week_outlined),
    TipoCarreta('bau', 'Baú', Icons.inventory_2_outlined),
    TipoCarreta('carga_seca', 'Carga seca', Icons.local_shipping_outlined),
    TipoCarreta('graneleiro', 'Graneleiro', Icons.grain_outlined),
    TipoCarreta('tanque', 'Tanque', Icons.water_drop_outlined),
    TipoCarreta('camara_fria', 'Câmara fria', Icons.ac_unit_outlined),
    TipoCarreta('cacamba', 'Caçamba', Icons.delete_outline),
    TipoCarreta('prancha', 'Prancha', Icons.horizontal_rule_outlined),
    TipoCarreta('porta_container', 'Porta-contêiner', Icons.widgets_outlined),
    TipoCarreta('outro', 'Outro', Icons.more_horiz),
  ];

  static const padrao = 'carga_seca';

  /// Resolve um código vindo da API. Código desconhecido cai em "Outro".
  static TipoCarreta de(dynamic codigo) {
    final c = codigo?.toString();
    return todos.firstWhere(
      (t) => t.codigo == c,
      orElse: () => todos.last,
    );
  }

  /// Rótulo pronto para exibição (usa o `tipo_carreta_display` da API quando
  /// ele vier preenchido).
  static String labelDe(Map<String, dynamic> carga) {
    final display = carga['tipo_carreta_display']?.toString();
    if (display != null && display.isNotEmpty) return display;
    return de(carga['tipo_carreta']).label;
  }

  static IconData iconeDe(Map<String, dynamic> carga) =>
      de(carga['tipo_carreta']).icone;
}
