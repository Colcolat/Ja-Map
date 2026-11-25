import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamap_app/core/widgets/server_unavailable_view.dart';
import 'package:jamap_app/features/incidencias/models/incidencia_resumen.dart';
import 'package:jamap_app/features/incidencias/screens/incidencias_screen.dart';
import 'package:jamap_app/features/incidencias/services/incidencia_api_service.dart';

class _FakeIncidenciaApiService extends IncidenciaApiService {
  final List<IncidenciaResumen> items;
  final bool shouldFail;
  String? lastTipo;
  String? lastQuery;

  _FakeIncidenciaApiService({
    this.items = const [],
    this.shouldFail = false,
  });

  @override
  Future<List<IncidenciaResumen>> fetchIncidencias({
    String? tipo,
    String? estado,
    String? q,
    int page = 0,
    int size = 25,
  }) async {
    lastTipo = tipo;
    lastQuery = q;
    if (shouldFail) {
      throw Exception('Connection refused');
    }
    return items.where((item) {
      final matchesTipo = tipo == null || item.tipo == tipo;
      final matchesQ = q == null ||
          q.isEmpty ||
          item.direccionFormateada.toLowerCase().contains(q.toLowerCase());
      return matchesTipo && matchesQ;
    }).toList();
  }
}

void main() {
  test('IncidenciaResumen.fromJson parsea imageUrl y formatea direccion de Merida', () {
    final json = <String, dynamic>{
      'id': 1,
      'tipo': 'FUGA_VIA_PUBLICA',
      'estado': 'ABIERTA',
      'latitud': 20.96745,
      'longitud': -89.62371,
      'calle': 'Calle 60',
      'numero': '485',
      'cruzamiento1': '55',
      'cruzamiento2': '57',
      'colonia': 'Centro',
      'prioridad': 66,
      'costoEstimado': 4200.0,
      'totalReportes': 5,
      'imageUrl': 'https://example.supabase.co/storage/v1/object/public/incidencias/fuga1.jpg',
      'fechaApertura': '2026-11-12T10:00:00Z',
    };

    final incidencia = IncidenciaResumen.fromJson(json);

    expect(incidencia.id, 1);
    expect(incidencia.tipoLabel, 'Fuga en vía pública');
    expect(incidencia.estadoLabel, 'Abierta');
    expect(incidencia.direccionFormateada, 'Calle 60 #485 x 55 y 57, Centro');
    expect(incidencia.imageUrl, contains('supabase.co'));
    expect(incidencia.costoFormateado, '\$4200 MXN');
    expect(incidencia.esPrioridadAlta, isTrue);
    expect(incidencia.totalReportes, 5);
  });

  testWidgets('ServerUnavailableView muestra mensaje y ejecuta callback al pulsar Reintentar', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServerUnavailableView(
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Servidor no disponible'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
  });

  testWidgets('IncidenciasScreen renderiza tarjetas, badge Prioridad alta y filtra por chip', (tester) async {
    final fakeApi = _FakeIncidenciaApiService(
      items: const [
        IncidenciaResumen(
          id: 1,
          tipo: 'FUGA_VIA_PUBLICA',
          estado: 'ABIERTA',
          calle: 'Calle 60',
          numero: '485',
          colonia: 'Centro',
          prioridad: 66,
          costoEstimado: 4200,
          totalReportes: 5,
        ),
        IncidenciaResumen(
          id: 2,
          tipo: 'BAJA_PRESION',
          estado: 'ASIGNADA',
          calle: 'Calle 7',
          colonia: 'Altabrisa',
          prioridad: 30,
          totalReportes: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: IncidenciasScreen(apiService: fakeApi)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fuga en vía pública'), findsOneWidget);
    expect(find.text('Prioridad alta'), findsOneWidget);
    expect(find.text('Calle 7, Altabrisa'), findsOneWidget);

    await tester.tap(find.text('Vía pública'));
    await tester.pumpAndSettle();

    expect(fakeApi.lastTipo, 'FUGA_VIA_PUBLICA');
    expect(find.text('Fuga en vía pública'), findsOneWidget);
    expect(find.text('Calle 7, Altabrisa'), findsNothing);
  });

  testWidgets('IncidenciasScreen muestra ServerUnavailableView si falla el servidor', (tester) async {
    final fakeApi = _FakeIncidenciaApiService(shouldFail: true);

    await tester.pumpWidget(
      MaterialApp(home: IncidenciasScreen(apiService: fakeApi)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Servidor no disponible'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
