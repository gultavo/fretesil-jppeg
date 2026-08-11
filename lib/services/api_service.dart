import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ─── URL base automática por plataforma ───────────────────────────────────
  // Web / iOS Simulator  → localhost
  // Android Emulator     → 10.0.2.2  (apelido do host dentro do AVD)
  // Dispositivo físico   → ajuste para o IP da sua máquina na rede local
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api'; // iOS simulator / desktop
  }

  /// Resolve uma URL de mídia (foto) que pode vir absoluta ou relativa da API.
  static String? mediaUrl(dynamic path) {
    if (path == null) return null;
    final p = path.toString();
    if (p.isEmpty) return null;
    if (p.startsWith('http')) return p;
    final root = baseUrl.replaceAll('/api', '');
    return p.startsWith('/') ? '$root$p' : '$root/$p';
  }

  // ─── Headers padrão ───────────────────────────────────────────────────────
  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
  };

  static Future<String> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  static Future<Map<String, String>> get _authHeaders async {
    final token = await _token;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/token/'),
          headers: _jsonHeaders,
          body: jsonEncode({'username': email, 'password': senha}),
        )
        .timeout(const Duration(seconds: 15));

    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  // ─── Cadastro ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> cadastrarEmpresa(
    Map<String, String> dados,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/cadastro_usuario/empresas/'),
          headers: _jsonHeaders,
          body: jsonEncode(dados),
        )
        .timeout(const Duration(seconds: 15));

    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> cadastrarCaminhoneiro(
    Map<String, String> dados,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/cadastro_usuario/caminhoneiros/'),
          headers: _jsonHeaders,
          body: jsonEncode(dados),
        )
        .timeout(const Duration(seconds: 15));

    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  // ─── Cargas ───────────────────────────────────────────────────────────────
  static Future<List<dynamic>> listarCargasDisponiveis() async {
    final headers = await _authHeaders;
    final response = await http
        .get(
          Uri.parse('$baseUrl/fretes/cargas/?status=disponivel'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Falha ao carregar cargas: ${response.statusCode}');
  }

  static Future<List<dynamic>> listarCargasEmpresa() async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/fretes/cargas/'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Falha ao carregar cargas: ${response.statusCode}');
  }

  /// Cria uma carga. Aceita foto opcional (upload multipart).
  static Future<Map<String, dynamic>> criarCarga(
    Map<String, dynamic> dados, {
    XFile? foto,
  }) async {
    final token = await _token;
    final uri = Uri.parse('$baseUrl/fretes/cargas/');

    if (foto == null) {
      final response = await http
          .post(uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(dados))
          .timeout(const Duration(seconds: 15));
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    }

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';
    dados.forEach((k, v) => request.fields[k] = v.toString());
    request.files.add(http.MultipartFile.fromBytes(
      'foto_carga',
      await foto.readAsBytes(),
      filename: foto.name,
    ));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  /// Motorista se candidata a uma carga (a empresa decide depois).
  static Future<Map<String, dynamic>> candidatarCarga(
    int cargaId, {
    String mensagem = '',
  }) async {
    final headers = await _authHeaders;
    final response = await http
        .post(
          Uri.parse('$baseUrl/fretes/cargas/$cargaId/candidatar/'),
          headers: headers,
          body: jsonEncode({'mensagem': mensagem}),
        )
        .timeout(const Duration(seconds: 15));
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  /// Candidaturas do motorista logado (com status de cada pedido).
  static Future<List<dynamic>> minhasCandidaturas() async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/fretes/cargas/minhas-candidaturas/'),
            headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  /// Empresa lista os candidatos de uma carga.
  static Future<List<dynamic>> candidatosDaCarga(int cargaId) async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/fretes/cargas/$cargaId/candidaturas/'),
            headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Falha ao carregar candidatos: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> aceitarCandidatura(int candidaturaId) async {
    final headers = await _authHeaders;
    final response = await http
        .post(Uri.parse('$baseUrl/fretes/candidaturas/$candidaturaId/aceitar/'),
            headers: headers)
        .timeout(const Duration(seconds: 15));
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  static Future<bool> recusarCandidatura(int candidaturaId) async {
    final headers = await _authHeaders;
    final response = await http
        .post(Uri.parse('$baseUrl/fretes/candidaturas/$candidaturaId/recusar/'),
            headers: headers)
        .timeout(const Duration(seconds: 15));
    return response.statusCode == 200;
  }

  /// Motorista confirma a carga que a empresa aprovou para ele.
  /// A viagem passa para a etapa "Acoplar carreta".
  static Future<Map<String, dynamic>> aceitarCarga(int cargaId) =>
      _acaoDoMotorista(cargaId, 'aceitar');

  /// Motorista acoplou a carreta e saiu para a estrada ("Em trânsito").
  static Future<Map<String, dynamic>> iniciarViagem(int cargaId) =>
      _acaoDoMotorista(cargaId, 'iniciar-viagem');

  /// Motorista desiste da viagem; a carga volta para a lista de disponíveis.
  static Future<Map<String, dynamic>> cancelarViagem(int cargaId) =>
      _acaoDoMotorista(cargaId, 'cancelar');

  static Future<Map<String, dynamic>> _acaoDoMotorista(
    int cargaId,
    String acao,
  ) async {
    final headers = await _authHeaders;
    final response = await http
        .post(Uri.parse('$baseUrl/fretes/cargas/$cargaId/$acao/'),
            headers: headers)
        .timeout(const Duration(seconds: 15));
    return {
      'statusCode': response.statusCode,
      'body': response.body.isEmpty ? {} : jsonDecode(response.body),
    };
  }

  /// Empresa marca a carga como entregue/finalizada.
  static Future<bool> finalizarCarga(int cargaId) async {
    final headers = await _authHeaders;
    final response = await http
        .post(Uri.parse('$baseUrl/fretes/cargas/$cargaId/finalizar/'),
            headers: headers)
        .timeout(const Duration(seconds: 15));
    return response.statusCode == 200;
  }

  /// Entregas finalizadas do motorista (para avaliar a empresa).
  static Future<List<dynamic>> minhasEntregas() async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/fretes/cargas/minhas-entregas/'), headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>?> cargaAtiva() async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/fretes/cargas/ativa/'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  // ─── Perfil ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> perfilCaminhoneiro() async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/usuario/motoristas/me/'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Falha ao carregar perfil');
  }

  /// Perfil público de um motorista (inclui as avaliações recebidas).
  static Future<Map<String, dynamic>> perfilMotoristaPublico(int id) async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/usuario/motoristas/$id/'), headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Falha ao carregar perfil do motorista');
  }

  /// Atualiza o perfil do motorista logado (campos + foto opcional).
  static Future<Map<String, dynamic>> atualizarPerfilMotorista(
    Map<String, dynamic> campos, {
    XFile? foto,
  }) async {
    final token = await _token;
    final uri = Uri.parse('$baseUrl/usuario/motoristas/me/');

    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Bearer $token';
    campos.forEach((k, v) => request.fields[k] = v.toString());
    if (foto != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'foto_perfil',
        await foto.readAsBytes(),
        filename: foto.name,
      ));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> perfilEmpresa() async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/usuario/empresas/me/'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Falha ao carregar perfil');
  }

  /// Perfil público de uma empresa (inclui as avaliações recebidas).
  static Future<Map<String, dynamic>> perfilEmpresaPublico(int id) async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/usuario/empresas/$id/'), headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Falha ao carregar perfil da empresa');
  }

  /// Atualiza o perfil da empresa logada (campos + logo opcional).
  static Future<Map<String, dynamic>> atualizarPerfilEmpresa(
    Map<String, dynamic> campos, {
    XFile? logo,
  }) async {
    final token = await _token;
    final uri = Uri.parse('$baseUrl/usuario/empresas/me/');

    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Bearer $token';
    campos.forEach((k, v) => request.fields[k] = v.toString());
    if (logo != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'logo',
        await logo.readAsBytes(),
        filename: logo.name,
      ));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  // ─── Avaliação ──────────────────────────────────────────────────────────
  /// Empresa avalia o motorista após a entrega (0-5 estrelas + comentário).
  static Future<Map<String, dynamic>> avaliarMotorista({
    required int caminhoneiroId,
    required int cargaId,
    required int nota,
    required String comentario,
    bool entregaNoPrazo = true,
    bool cuidadoComCarga = true,
  }) async {
    final headers = await _authHeaders;
    final response = await http
        .post(
          Uri.parse('$baseUrl/avaliacao/avaliar-caminhoneiro/'),
          headers: headers,
          body: jsonEncode({
            'caminhoneiro': caminhoneiroId,
            'carga': cargaId,
            'nota': nota,
            'comentario': comentario,
            'entrega_no_prazo': entregaNoPrazo,
            'cuidado_com_carga': cuidadoComCarga,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  /// Motorista avalia a empresa após a entrega (0-5 estrelas + comentário).
  static Future<Map<String, dynamic>> avaliarEmpresa({
    required int cargaId,
    required int nota,
    required String comentario,
    bool temBanheiroLimpo = true,
    bool localSeguro = true,
  }) async {
    final headers = await _authHeaders;
    final response = await http
        .post(
          Uri.parse('$baseUrl/avaliacao/blacklist/'),
          headers: headers,
          body: jsonEncode({
            'carga': cargaId,
            'nota': nota,
            'comentario': comentario,
            'tem_banheiro_limpo': temBanheiroLimpo,
            'local_seguro': localSeguro,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('tipo_usuario');
  }
}
