/// Configuracion central de red para conectar con el backend Spring Boot (:8090/api).
///
/// Ejemplos de ejecucion:
/// - macOS / Web / Celular por USB con `adb reverse tcp:8090 tcp:8090`:
///   `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8090/api`
/// - Emulador Android:
///   `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090/api`
/// - Celular fisico en misma red Wi-Fi / Hotspot:
///   `flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8090/api`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8090/api',
  );
}
