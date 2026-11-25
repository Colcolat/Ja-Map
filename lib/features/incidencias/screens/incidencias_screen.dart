import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/widgets/server_unavailable_view.dart';
import '../models/incidencia_resumen.dart';
import '../services/incidencia_api_service.dart';

/// Catalogo profesional de incidencias en estetica oscura estanque/ASCII:
/// - Tarjetas modernas con Image.network + errorBuilder y badge "Prioridad alta".
/// - Buscador por calle/colonia (`q`) y chips de filtro por categoria (`tipo`).
/// - Vista amigable "Servidor no disponible" con boton "Reintentar" y boton Cerrar sesion.
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
  static const Color _pondBg = Color(0xFF061010);
  static const Color _cardBg = Color(0xFF0B1C1C);
  static const Color _borderIdle = Color(0xFF234D4B);
  static const Color _accentAqua = Color(0xFF5EEAD4);
  static const Color _accentJade = Color(0xFF0D9488);
  static const Color _accentGold = Color(0xFFF59E0B);
  static const Color _textLight = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF7FA6A4);

  static const List<({String? value, String label})> _categorias = [
    (value: null, label: 'Todas'),
    (value: 'FUGA_VIA_PUBLICA', label: 'Vía pública'),
    (value: 'FUGA_TOMA_DOMICILIARIA', label: 'Toma domic.'),
    (value: 'SIN_SERVICIO', label: 'Sin servicio'),
    (value: 'BAJA_PRESION', label: 'Baja presión'),
  ];

  late final IncidenciaApiService _apiService;
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  String? _selectedTipo;
  String _searchQuery = '';
  late Future<List<IncidenciaResumen>> _incidenciasFuture;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? IncidenciaApiService();
    _incidenciasFuture = _cargarIncidencias();
  }

  Future<List<IncidenciaResumen>> _cargarIncidencias() {
    return _apiService.fetchIncidencias(
      tipo: _selectedTipo,
      q: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  void _recargar() {
    setState(() {
      _incidenciasFuture = _cargarIncidencias();
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
        _incidenciasFuture = _cargarIncidencias();
      });
    });
  }

  void _onSelectTipo(String? tipo) {
    if (_selectedTipo == tipo) return;
    setState(() {
      _selectedTipo = tipo;
      _incidenciasFuture = _cargarIncidencias();
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
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pondBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1717),
        foregroundColor: _textLight,
        title: const Text(
          '> Ja’Map · Incidencias',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _accentAqua,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderIdle),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded, color: _accentAqua),
            onPressed: _recargar,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: _accentGold),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda + chips de categoría
          Container(
            color: const Color(0xFF081414),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    color: _textLight,
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                  ),
                  cursorColor: _accentAqua,
                  decoration: InputDecoration(
                    hintText: 'Buscar por calle o colonia...',
                    hintStyle: const TextStyle(
                      color: _textMuted,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _accentAqua,
                      size: 20,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _textMuted,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              _searchDebounce?.cancel();
                              setState(() {
                                _searchQuery = '';
                                _incidenciasFuture = _cargarIncidencias();
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: _cardBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _borderIdle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _accentAqua, width: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categorias.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categorias[index];
                      final selected = _selectedTipo == cat.value;
                      return ChoiceChip(
                        label: Text(
                          cat.label,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            color: selected ? Colors.white : _textMuted,
                          ),
                        ),
                        selected: selected,
                        selectedColor: _accentJade,
                        backgroundColor: _cardBg,
                        side: BorderSide(
                          color: selected ? _accentAqua : _borderIdle,
                        ),
                        showCheckmark: false,
                        onSelected: (_) => _onSelectTipo(cat.value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista de tarjetas
          Expanded(
            child: FutureBuilder<List<IncidenciaResumen>>(
              future: _incidenciasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accentAqua),
                  );
                }
                if (snapshot.hasError) {
                  return ServerUnavailableView(onRetry: _recargar);
                }

                final incidencias = snapshot.data ?? const [];
                if (incidencias.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.water_drop_outlined,
                            size: 48,
                            color: _borderIdle,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No se encontraron incidencias con esos filtros.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: _textMuted,
                            ),
                          ),
                          if (_selectedTipo != null || _searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _selectedTipo = null;
                                  _searchQuery = '';
                                  _incidenciasFuture = _cargarIncidencias();
                                });
                              },
                              child: const Text(
                                'Limpiar filtros',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: _accentAqua,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: _accentAqua,
                  backgroundColor: _cardBg,
                  onRefresh: () async => _recargar(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    itemCount: incidencias.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _IncidenciaCard(item: incidencias[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidenciaCard extends StatelessWidget {
  final IncidenciaResumen item;

  const _IncidenciaCard({required this.item});

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'ABIERTA':
        return const Color(0xFFEA580C);
      case 'ASIGNADA':
        return const Color(0xFFF59E0B);
      case 'EN_REPARACION':
        return const Color(0xFF0284C7);
      case 'CERRADA':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor(item.estado);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1C1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.esPrioridadAlta
              ? const Color(0xFFEA580C).withValues(alpha: 0.65)
              : const Color(0xFF234D4B),
          width: item.esPrioridadAlta ? 1.3 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen superior desde imageUrl (Supabase Storage / URL publica) con errorBuilder
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty)
                  Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFF091616),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF5EEAD4),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => _ImageFallback(label: item.tipoLabel),
                  )
                else
                  _ImageFallback(label: item.tipoLabel),

                // Degradado inferior sobre la foto para legibilidad de badges
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF061010).withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),
                ),

                // Badges superiores: Estado + Prioridad alta
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _PillBadge(
                        label: item.estadoLabel.toUpperCase(),
                        background: estadoColor.withValues(alpha: 0.92),
                        foreground: Colors.white,
                      ),
                      const Spacer(),
                      if (item.esPrioridadAlta)
                        const _PillBadge(
                          label: 'Prioridad alta',
                          background: Color(0xFFEA580C),
                          foreground: Colors.white,
                          icon: Icons.warning_amber_rounded,
                        ),
                    ],
                  ),
                ),

                // ID y prioridad en esquina inferior derecha
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Text(
                    '#${item.id} · P${item.prioridad}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF5EEAD4),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido de la tarjeta
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.tipoLabel,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFFE2E8F0),
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF5EEAD4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.direccionFormateada,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF94B8B6),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${item.totalReportes} ${item.totalReportes == 1 ? 'reporte' : 'reportes'}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (item.costoFormateado != null)
                      Text(
                        item.costoFormateado!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF5EEAD4),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const _PillBadge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final String label;

  const _ImageFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF091616),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.water_drop_rounded,
            size: 36,
            color: Color(0xFF234D4B),
          ),
          const SizedBox(height: 6),
          Text(
            '~ $label ~',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF5E8A88),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
