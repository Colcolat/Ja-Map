/// Configuracion central de red para conectar con el backend Spring Boot (:8090/api).
///
/// Ejemplos de ejecucion:
/// - Celular por USB con `adb reverse tcp:8090 tcp:8090`:
///   `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8090/api`
/// - Celular sin USB (misma red Wi-Fi o hotspot hacia la Mac):
///   `flutter run --dart-define=API_BASE_URL=http://<IP_LOCAL_MAC>:8090/api`
/// - Emulador Android:
///   `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090/api`
class ApiConfig {
  ApiConfig._();

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8090/api',
  );

  static String? _overrideBaseUrl;

  static String get baseUrl => _overrideBaseUrl ?? _defaultBaseUrl;

  static void setOverrideBaseUrl(String? url) {
    final cleaned = url?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      _overrideBaseUrl = null;
      return;
    }
    _overrideBaseUrl =
        cleaned.endsWith('/') ? cleaned.substring(0, cleaned.length - 1) : cleaned;
  }
}
