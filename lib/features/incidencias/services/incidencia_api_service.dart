import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../models/incidencia_resumen.dart';

/// Cliente HTTP para consultar incidencias en el backend Spring Boot.
class IncidenciaApiService {
  final http.Client _client;

  IncidenciaApiService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<IncidenciaResumen>> fetchIncidencias({
    String? tipo,
    String? estado,
    String? q,
    int page = 0,
    int size = 25,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (tipo != null && tipo.isNotEmpty) queryParams['tipo'] = tipo;
    if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
    if (q != null && q.trim().isNotEmpty) queryParams['q'] = q.trim();

    final uri = Uri.parse('${ApiConfig.baseUrl}/incidencias')
        .replace(queryParameters: queryParams);

    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception(
        'Error HTTP ${response.statusCode} al consultar incidencias.',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final List<dynamic> items = decoded is Map<String, dynamic>
        ? (decoded['content'] as List<dynamic>? ?? const [])
        : (decoded as List<dynamic>);

    return items
        .whereType<Map<String, dynamic>>()
        .map(IncidenciaResumen.fromJson)
        .toList();
  }
}
