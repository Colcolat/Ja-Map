import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamap_app/core/widgets/server_unavailable_view.dart';
import 'package:jamap_app/features/incidencias/models/incidencia_resumen.dart';

void main() {
  test('IncidenciaResumen.fromJson parsea respuesta de Spring Boot y formatea direccion de Merida', () {
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
      'fotoPrincipalUrl': 'https://placehold.co/800x600',
      'fechaApertura': '2026-11-12T10:00:00Z',
    };

    final incidencia = IncidenciaResumen.fromJson(json);

    expect(incidencia.id, 1);
    expect(incidencia.tipoLabel, 'Fuga en vía pública');
    expect(incidencia.estadoLabel, 'Abierta');
    expect(incidencia.direccionFormateada, 'Calle 60 #485 x 55 y 57, Centro');
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
}
