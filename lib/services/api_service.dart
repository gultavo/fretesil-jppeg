import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  // ─── Headers padrão ───────────────────────────────────────────────────────
  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
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
        .get(
          Uri.parse('$baseUrl/fretes/cargas/'),
          headers: headers,
        ) // ← sem /minhas/
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Falha ao carregar cargas: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> criarCarga(
    Map<String, dynamic> dados,
  ) async {
    final headers = await _authHeaders;
    final response = await http
        .post(
          Uri.parse('$baseUrl/fretes/cargas/'),
          headers: headers,
          body: jsonEncode(dados),
        )
        .timeout(const Duration(seconds: 15));

    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  static Future<bool> aceitarCarga(int cargaId) async {
    final headers = await _authHeaders;
    final response = await http
        .post(
          Uri.parse('$baseUrl/fretes/cargas/$cargaId/aceitar-carga/'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    return response.statusCode == 200;
  }

  // ─── Perfil ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> perfilCaminhoneiro() async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/usuario/motorista/me/'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Falha ao carregar perfil');
  }

  static Future<Map<String, dynamic>> perfilEmpresa() async {
    final headers = await _authHeaders;
    final response = await http
        .get(Uri.parse('$baseUrl/usuario/empresa/me/'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Falha ao carregar perfil');
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

  // ─── Logout ───────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('tipo_usuario');
  }
}
