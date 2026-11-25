import 'package:flutter/material.dart';

/// Vista reutilizable de "Servidor no disponible" con boton "Reintentar"
/// en estetica oscura ASCII armonizada con Ja'Map.
class ServerUnavailableView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ServerUnavailableView({
    super.key,
    this.message =
        'No fue posible conectar con el servidor de Ja’Map. Verifica que Spring Boot esté activo en el puerto 8090.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1C1C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF234D4B)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: Color(0xFF5EEAD4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Servidor no disponible',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFE2E8F0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF7FA6A4),
                  fontSize: 12.5,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF5EEAD4)),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
