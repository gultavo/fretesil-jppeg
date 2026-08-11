import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Falha ao calcular a distância, já com uma mensagem pronta para a tela.
class GeoErro implements Exception {
  final String mensagem;
  const GeoErro(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Resultado do cálculo automático de distância.
///
/// [aproximada] indica que não foi possível traçar a rota por estrada e o
/// valor veio da distância em linha reta com um acréscimo médio de estrada.
typedef DistanciaCalculada = ({
  double km,
  String origem,
  String destino,
  bool aproximada,
});

/// Distância rodoviária entre duas cidades, usando serviços públicos e
/// gratuitos do OpenStreetMap (sem chave de API):
///
/// * **Nominatim** converte "Curitiba, PR" em coordenadas;
/// * **OSRM** traça a rota por estrada entre as coordenadas.
///
/// Se o OSRM não responder, cai para a distância em linha reta acrescida de
/// 25% (fator médio de sinuosidade das rodovias) e marca o resultado como
/// aproximado.
abstract final class GeoService {
  static const _timeout = Duration(seconds: 20);

  /// O Nominatim exige identificação do aplicativo. Na web o navegador
  /// define o `User-Agent` sozinho e proíbe sobrescrevê-lo.
  static Map<String, String> get _headers =>
      kIsWeb ? const {} : const {'User-Agent': 'FreteSil/1.0 (app de fretes)'};

  static Future<DistanciaCalculada> distanciaEntre(
    String origem,
    String destino,
  ) async {
    if (origem.trim().isEmpty || destino.trim().isEmpty) {
      throw const GeoErro('Preencha a origem e o destino primeiro.');
    }

    final a = await _coordenadas(origem);
    final b = await _coordenadas(destino);

    final rota = await _rotaPorEstrada(a, b);
    if (rota != null) {
      return (
        km: rota,
        origem: a.nome,
        destino: b.nome,
        aproximada: false,
      );
    }

    return (
      km: _haversineKm(a, b) * 1.25,
      origem: a.nome,
      destino: b.nome,
      aproximada: true,
    );
  }

  // ─── Geocodificação (cidade → coordenadas) ────────────────────────────────
  static Future<_Ponto> _coordenadas(String local) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': local.trim(),
      'format': 'json',
      'limit': '1',
      'countrycodes': 'br',
      'accept-language': 'pt-BR',
    });

    late final http.Response resposta;
    try {
      resposta = await http.get(uri, headers: _headers).timeout(_timeout);
    } catch (_) {
      throw const GeoErro(
        'Não foi possível consultar o mapa. Verifique a internet.',
      );
    }

    if (resposta.statusCode != 200) {
      throw const GeoErro('O serviço de mapas não respondeu. Tente de novo.');
    }

    final lista = jsonDecode(resposta.body) as List<dynamic>;
    if (lista.isEmpty) {
      throw GeoErro('Cidade não encontrada: "$local".');
    }

    final item = lista.first as Map<String, dynamic>;
    return _Ponto(
      lat: double.parse(item['lat'].toString()),
      lon: double.parse(item['lon'].toString()),
      nome: item['display_name']?.toString() ?? local,
    );
  }

  // ─── Rota por estrada ─────────────────────────────────────────────────────
  static Future<double?> _rotaPorEstrada(_Ponto a, _Ponto b) async {
    final coords = '${a.lon},${a.lat};${b.lon},${b.lat}';
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coords',
      {'overview': 'false'},
    );

    try {
      final resposta = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resposta.statusCode != 200) return null;

      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      final rotas = corpo['routes'] as List<dynamic>?;
      if (rotas == null || rotas.isEmpty) return null;

      final metros = (rotas.first as Map<String, dynamic>)['distance'] as num?;
      return metros == null ? null : metros / 1000;
    } catch (_) {
      return null; // cai para a estimativa em linha reta
    }
  }

  // ─── Distância em linha reta ──────────────────────────────────────────────
  static double _haversineKm(_Ponto a, _Ponto b) {
    const raioTerra = 6371.0;
    final dLat = _rad(b.lat - a.lat);
    final dLon = _rad(b.lon - a.lon);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.lat)) *
            math.cos(_rad(b.lat)) *
            math.pow(math.sin(dLon / 2), 2);
    return raioTerra * 2 * math.asin(math.sqrt(h.toDouble()));
  }

  static double _rad(double graus) => graus * math.pi / 180;
}

class _Ponto {
  final double lat;
  final double lon;
  final String nome;

  const _Ponto({required this.lat, required this.lon, required this.nome});
}
