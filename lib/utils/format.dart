/// Formatações compartilhadas — antes duplicadas em cada tela, com resultados
/// ligeiramente diferentes ("R$ 1500.00" vs "R$ 1.500,00").
abstract final class Fmt {
  /// `1500.5` → `R$ 1.500,50`. Nulo/inválido → `R$ —`.
  static String brl(dynamic valor) {
    final d = _toDouble(valor);
    if (d == null) return r'R$ —';
    final sinal = d < 0 ? '-' : '';
    return '${sinal}R\$ ${_milhar(d.abs().toStringAsFixed(2))}';
  }

  /// `1500.5` → `R$ 1,5 mil` — para os cartões de resumo.
  static String brlCompacto(dynamic valor) {
    final d = _toDouble(valor) ?? 0;
    if (d < 1000) return brl(d);
    final mil = d / 1000;
    return 'R\$ ${mil.toStringAsFixed(1).replaceAll('.', ',')} mil';
  }

  /// `1234.7` → `1.235 km`. Nulo/inválido → `— km`.
  static String km(dynamic valor) {
    final d = _toDouble(valor);
    if (d == null) return '— km';
    return '${_milhar(d.toStringAsFixed(0))} km';
  }

  /// `4.25` → `4,3`. Nulo/inválido → `0,0`.
  static String nota(dynamic valor) =>
      (_toDouble(valor) ?? 0).toStringAsFixed(1).replaceAll('.', ',');

  /// Texto digitado pelo usuário (`"1.500,00"`) → `1500.0`.
  /// Lança [FormatException] se não for número — use dentro de validadores.
  static double parseEntrada(String v) =>
      double.parse(v.trim().replaceAll('.', '').replaceAll(',', '.'));

  /// Versão tolerante de [parseEntrada]: devolve nulo em vez de lançar.
  static double? tryParseEntrada(String v) =>
      double.tryParse(v.trim().replaceAll('.', '').replaceAll(',', '.'));

  /// Valor pequeno com casas decimais (`"6,50"` ou `"6.50"`) → `6.5`.
  /// Aqui o ponto é decimal, nunca separador de milhar.
  static double? tryParseDecimal(String v) =>
      double.tryParse(v.trim().replaceAll(',', '.'));

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Aplica separador de milhar e vírgula decimal a um número já formatado
  /// no padrão inglês (`1500.50` → `1.500,50`).
  static String _milhar(String fixo) {
    final partes = fixo.split('.');
    final inteiro = partes.first;
    final decimal = partes.length > 1 ? partes[1] : null;

    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
      buffer.write(inteiro[i]);
    }
    return decimal == null ? buffer.toString() : '$buffer,$decimal';
  }
}
