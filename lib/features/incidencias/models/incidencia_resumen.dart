/// Modelo que representa cada elemento devuelto por `GET /api/incidencias` en Spring Boot.
class IncidenciaResumen {
  final int id;
  final String tipo;
  final String estado;
  final double? latitud;
  final double? longitud;
  final String? calle;
  final String? numero;
  final String? cruzamiento1;
  final String? cruzamiento2;
  final String? colonia;
  final int prioridad;
  final double? costoEstimado;
  final String? asignadoA;
  final String? fotoPrincipalUrl;
  final int totalReportes;
  final DateTime? fechaApertura;
  final DateTime? fechaCierre;

  const IncidenciaResumen({
    required this.id,
    required this.tipo,
    required this.estado,
    this.latitud,
    this.longitud,
    this.calle,
    this.numero,
    this.cruzamiento1,
    this.cruzamiento2,
    this.colonia,
    required this.prioridad,
    this.costoEstimado,
    this.asignadoA,
    this.fotoPrincipalUrl,
    required this.totalReportes,
    this.fechaApertura,
    this.fechaCierre,
  });

  factory IncidenciaResumen.fromJson(Map<String, dynamic> json) {
    return IncidenciaResumen(
      id: (json['id'] as num).toInt(),
      tipo: (json['tipo'] ?? 'FUGA_VIA_PUBLICA').toString(),
      estado: (json['estado'] ?? 'ABIERTA').toString(),
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      calle: json['calle'] as String?,
      numero: json['numero'] as String?,
      cruzamiento1: json['cruzamiento1'] as String?,
      cruzamiento2: json['cruzamiento2'] as String?,
      colonia: json['colonia'] as String?,
      prioridad: (json['prioridad'] as num?)?.toInt() ?? 0,
      costoEstimado: (json['costoEstimado'] as num?)?.toDouble(),
      asignadoA: json['asignadoA'] as String?,
      fotoPrincipalUrl: json['fotoPrincipalUrl'] as String?,
      totalReportes: (json['totalReportes'] as num?)?.toInt() ?? 0,
      fechaApertura: json['fechaApertura'] != null
          ? DateTime.tryParse(json['fechaApertura'].toString())
          : null,
      fechaCierre: json['fechaCierre'] != null
          ? DateTime.tryParse(json['fechaCierre'].toString())
          : null,
    );
  }

  /// Nombre legible de la categoria / tipo de incidencia.
  String get tipoLabel {
    switch (tipo) {
      case 'FUGA_VIA_PUBLICA':
        return 'Fuga en vía pública';
      case 'FUGA_TOMA_DOMICILIARIA':
        return 'Fuga en toma domiciliaria';
      case 'SIN_SERVICIO':
        return 'Sin servicio de agua';
      case 'BAJA_PRESION':
        return 'Baja presión';
      default:
        return tipo;
    }
  }

  /// Nombre legible del estado actual.
  String get estadoLabel {
    switch (estado) {
      case 'ABIERTA':
        return 'Abierta';
      case 'ASIGNADA':
        return 'Asignada';
      case 'EN_REPARACION':
        return 'En reparación';
      case 'CERRADA':
        return 'Cerrada';
      default:
        return estado;
    }
  }

  /// Direccion en formato tradicional de Merida: "Calle 60 #485 x 55 y 57, Centro".
  String get direccionFormateada {
    final partes = <String>[];
    if (calle != null && calle!.trim().isNotEmpty) {
      var base = calle!.trim();
      if (numero != null && numero!.trim().isNotEmpty) {
        base = '$base #${numero!.trim()}';
      }
      if (cruzamiento1 != null && cruzamiento1!.trim().isNotEmpty) {
        if (cruzamiento2 != null && cruzamiento2!.trim().isNotEmpty) {
          base = '$base x ${cruzamiento1!.trim()} y ${cruzamiento2!.trim()}';
        } else {
          base = '$base x ${cruzamiento1!.trim()}';
        }
      }
      partes.add(base);
    }
    if (colonia != null && colonia!.trim().isNotEmpty) {
      partes.add(colonia!.trim());
    }
    return partes.isEmpty ? 'Dirección sin especificar' : partes.join(', ');
  }

  bool get esPrioridadAlta => prioridad >= 50;
}
