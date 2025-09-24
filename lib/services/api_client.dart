// Archivo: services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';


/// Un cliente HTTP centralizado para gestionar las llamadas a la API.
/// Se encarga de inyectar el token de autenticación en las cabeceras.
class ApiClient {
  final http.Client _httpClient;
  final UserProvider _userProvider;

  ApiClient(this._userProvider, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  // Método genérico para realizar peticiones GET con autenticación.
  Future<http.Response> get(String url) async {
    final uri = Uri.parse(url);
    final headers = await _getHeaders();
    return await _httpClient.get(uri, headers: headers);
  }

  // Método genérico para realizar peticiones POST con autenticación y cuerpo.
  Future<http.Response> post(String url, {required Map<String, dynamic> body}) async {
    final uri = Uri.parse(url);
    final headers = await _getHeaders();
    return await _httpClient.post(uri, headers: headers, body: jsonEncode(body));
  }

  /// Retorna las cabeceras HTTP, incluyendo el token de autenticación si existe.
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
    };
    final token = _userProvider.fcmToken;
    if (token != null) {
      // ✅ [CAMBIO] Usamos print para un archivo puro de Dart.
      // O aún mejor, usamos log de dart:developer.
      print('📲 Enviando token de autenticación: $token');
      // log('Enviando token de autenticación: $token'); 
      headers['Authorization'] = 'Bearer $token';
    } else {
      print('⚠️ No se encontró token de autenticación. La petición se enviará sin token.');
    }
    return headers;
  }
}