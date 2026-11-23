import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/widgets/server_unavailable_view.dart';
import '../models/incidencia_resumen.dart';
import '../services/incidencia_api_service.dart';

/// Pantalla de catalogo conectada a GET /api/incidencias con boton de cerrar sesion en AppBar.
class IncidenciasScreen extends StatefulWidget {
  final IncidenciaApiService? apiService;
  final Future<void> Function()? onSignOut;

  const IncidenciasScreen({
    super.key,
    this.apiService,
    this.onSignOut,
  });

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  late final IncidenciaApiService _apiService;
  late Future<List<IncidenciaResumen>> _incidenciasFuture;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? IncidenciaApiService();
    _incidenciasFuture = _apiService.fetchIncidencias();
  }

  void _recargar() {
    setState(() {
      _incidenciasFuture = _apiService.fetchIncidencias();
    });
  }

  Future<void> _cerrarSesion() async {
    if (widget.onSignOut != null) {
      await widget.onSignOut!();
    } else {
      await FirebaseAuth.instance.signOut();
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ja’Map · Incidencias'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _recargar,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: FutureBuilder<List<IncidenciaResumen>>(
        future: _incidenciasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ServerUnavailableView(onRetry: _recargar);
          }

          final incidencias = snapshot.data ?? const [];
          if (incidencias.isEmpty) {
            return const Center(
              child: Text('No hay incidencias registradas todavía.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: incidencias.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = incidencias[index];
              return Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.esPrioridadAlta
                        ? Colors.orange.shade100
                        : Colors.lightBlue.shade100,
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: item.esPrioridadAlta
                          ? Colors.deepOrange
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    item.tipoLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.direccionFormateada}\nEstado: ${item.estadoLabel} · Reportes: ${item.totalReportes}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text('P${item.prioridad}'),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
