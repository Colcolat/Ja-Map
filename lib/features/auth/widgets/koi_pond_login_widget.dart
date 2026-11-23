import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Controlador imperativo del estanque Koi ASCII (analogo a los inputs de Rive:
/// isChecking, numLook, isHiding/isHandsUp, trigSuccess y trigFail).
class KoiPondController extends ChangeNotifier {
  bool _isChecking = false;
  bool _isHiding = false;
  bool _isPeeking = false;
  double _lookValue = 50.0; // 0 (izquierda) .. 100 (derecha)
  int _successTick = 0;
  int _failTick = 0;

  bool get isChecking => _isChecking;
  bool get isHiding => _isHiding;
  bool get isPeeking => _isPeeking;
  double get lookValue => _lookValue;
  int get successTick => _successTick;
  int get failTick => _failTick;

  void setChecking(bool value) {
    if (_isChecking == value) return;
    _isChecking = value;
    notifyListeners();
  }

  void setLook(double value) {
    final clamped = value.clamp(0.0, 100.0);
    if ((_lookValue - clamped).abs() < 0.1) return;
    _lookValue = clamped;
    notifyListeners();
  }

  void setHiding(bool value) {
    if (_isHiding == value) return;
    _isHiding = value;
    if (!value) _isPeeking = false;
    notifyListeners();
  }

  void setPeeking(bool value) {
    if (_isPeeking == value) return;
    _isPeeking = value;
    notifyListeners();
  }

  void trigSuccess() {
    _isChecking = false;
    _isHiding = false;
    _isPeeking = false;
    _successTick++;
    notifyListeners();
  }

  void trigFail() {
    _isChecking = false;
    _isHiding = false;
    _isPeeking = false;
    _failTick++;
    notifyListeners();
  }
}

class _Ripple {
  double x; // 0..1
  double y; // 0..1
  double progress = 0.0;
  Color color;
  double maxRadius;

  _Ripple({
    required this.x,
    required this.y,
    required this.color,
    this.maxRadius = 14.0,
  });
}

class _Bubble {
  final double x;
  final double y;
  final double phase;

  const _Bubble(this.x, this.y, this.phase);
}

class _SplashDrop {
  double x; // 0..1
  double y; // 0..1
  double vx;
  double vy;
  double z; // altura sobre el agua
  double vz;
  Color color;

  _SplashDrop({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.z,
    required this.vz,
    required this.color,
  });
}

class _Vec2 {
  double x;
  double y;

  _Vec2(this.x, this.y);
}

class _RenderNode {
  final double x;
  final double y;
  final double nx;
  final double ny;

  const _RenderNode(this.x, this.y, this.nx, this.ny);
}

class _SpineSeg {
  final double ax;
  final double ay;
  final double abx;
  final double aby;
  final double invLenSq;
  final double anx;
  final double any;
  final double dnx;
  final double dny;

  const _SpineSeg({
    required this.ax,
    required this.ay,
    required this.abx,
    required this.aby,
    required this.invLenSq,
    required this.anx,
    required this.any,
    required this.dnx,
    required this.dny,
  });
}

/// Estanque Koi interactivo portado directamente del motor PondEngine.swift de ASCIIKoiSaver:
/// proyeccion continua sobre espina dorsal, aletas pectorales con remo sutil (sin aleteo brusco),
/// cola bifurcada con retardo de seda, escamas 3D, branquias, aleta dorsal y profundidad en eje Z.
class KoiPondLoginWidget extends StatefulWidget {
  final KoiPondController controller;
  final double height;

  const KoiPondLoginWidget({
    super.key,
    required this.controller,
    this.height = 220,
  });

  @override
  State<KoiPondLoginWidget> createState() => _KoiPondLoginWidgetState();
}

class _KoiPondLoginWidgetState extends State<KoiPondLoginWidget>
    with SingleTickerProviderStateMixin {
  static const int _rows = 26;
  static const int _nodeCount = 24;
  // Espacio logico virtual de referencia (proporcional al PondEngine original)
  static const double _simWidth = 560.0;
  static const double _simHeight = 220.0;
  static const double _baseScale = 0.56;

  late final AnimationController _ticker;
  late final List<_Vec2> _nodes;
  List<_RenderNode> _renderNodes = const [];
  List<_SpineSeg> _segs = const [];

  double _time = 0.0;
  double _phase = 0.0;
  double _angle = 0.0;
  double _turnVel = 0.0;
  double _z = 0.85; // 1.0 = superficie, 0.1 = profundo bajo hoja de loto

  double _successAnim = 0.0;
  bool _breachLandingSplashed = false;
  double _failAnim = 0.0;
  int _lastSuccessTick = 0;
  int _lastFailTick = 0;

  final List<_Ripple> _ripples = [];
  final List<_SplashDrop> _splashDrops = [];
  final math.Random _rng = math.Random(42);
  static const List<_Bubble> _bubbles = [
    _Bubble(0.18, 0.80, 0.0),
    _Bubble(0.42, 0.28, 1.4),
    _Bubble(0.66, 0.82, 2.9),
    _Bubble(0.88, 0.72, 4.3),
    _Bubble(0.28, 0.44, 5.1),
  ];

  @override
  void initState() {
    super.initState();
    final segLen = 9.4 * _baseScale;
    _nodes = List.generate(
      _nodeCount,
      (i) => _Vec2(_simWidth * 0.48 - i * segLen, _simHeight * 0.54),
    );
    _rebuildRenderSpine(_baseScale);

    _lastSuccessTick = widget.controller.successTick;
    _lastFailTick = widget.controller.failTick;
    widget.controller.addListener(_onControllerChanged);

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_stepSimulation);
    _ticker.repeat();
  }

  void _onControllerChanged() {
    final head = _nodes[0];
    final nx = (head.x / _simWidth).clamp(0.0, 1.0);
    final ny = (head.y / _simHeight).clamp(0.0, 1.0);

    if (widget.controller.successTick != _lastSuccessTick) {
      _lastSuccessTick = widget.controller.successTick;
      _successAnim = 1.0;
      _breachLandingSplashed = false;
      _failAnim = 0.0;
      _spawnRipple(nx, ny, const Color(0xFF4ADE80), maxRadius: 22);
      _spawnRipple(nx, ny, const Color(0xFF38BDF8), maxRadius: 15);
      _spawnSplashBurst(nx, ny, count: 16, power: 1.0);
    }
    if (widget.controller.failTick != _lastFailTick) {
      _lastFailTick = widget.controller.failTick;
      _failAnim = 1.0;
      _successAnim = 0.0;
      _spawnRipple(nx, ny, const Color(0xFFF97316), maxRadius: 18);
      _spawnRipple(nx, ny, const Color(0xFFEF4444), maxRadius: 12);
    }
  }

  void _spawnSplashBurst(double nx, double ny, {int count = 14, double power = 1.0}) {
    for (int i = 0; i < count; i++) {
      final a = (i / count) * 2 * math.pi + (_rng.nextDouble() - 0.5) * 0.4;
      final spd = (0.10 + _rng.nextDouble() * 0.16) * power;
      _splashDrops.add(
        _SplashDrop(
          x: nx,
          y: ny,
          vx: math.cos(a) * spd,
          vy: math.sin(a) * spd * 0.65,
          z: 0.05,
          vz: (0.45 + _rng.nextDouble() * 0.45) * power,
          color: i.isEven ? const Color(0xFF7DD3FC) : const Color(0xFF4ADE80),
        ),
      );
    }
    if (_splashDrops.length > 40) {
      _splashDrops.removeRange(0, _splashDrops.length - 40);
    }
  }

  void _spawnRipple(
    double nx,
    double ny,
    Color color, {
    double maxRadius = 12.0,
  }) {
    _ripples.add(_Ripple(x: nx, y: ny, color: color, maxRadius: maxRadius));
    if (_ripples.length > 10) {
      _ripples.removeAt(0);
    }
  }

  void _stepSimulation() {
    const dt = 1 / 60.0;
    _time += dt;

    final c = widget.controller;

    if (_successAnim > 0) {
      _successAnim = math.max(0.0, _successAnim - dt * 0.68);
      // Salpicadura al caer de regreso al agua
      if (_successAnim < 0.18 && !_breachLandingSplashed) {
        _breachLandingSplashed = true;
        final h = _nodes[0];
        final nx = (h.x / _simWidth).clamp(0.0, 1.0);
        final ny = (h.y / _simHeight).clamp(0.0, 1.0);
        _spawnRipple(nx, ny, const Color(0xFF38BDF8), maxRadius: 24);
        _spawnRipple(nx, ny, const Color(0xFF4ADE80), maxRadius: 16);
        _spawnSplashBurst(nx, ny, count: 14, power: 1.15);
      }
    }
    if (_failAnim > 0) _failAnim = math.max(0.0, _failAnim - dt * 1.10);

    // Posicion objetivo y profundidad Z (1.0 = superficie, >1.0 = salto en el aire)
    double targetX;
    double targetY;
    double targetZ;

    if (_successAnim > 0) {
      final arch = math.sin(_successAnim * math.pi);
      targetX = _simWidth * 0.50 + math.cos(_time * 4.5) * 48;
      targetY = _simHeight * 0.54 - arch * 54; // arco pronunciado de salto
      targetZ = 0.95 + arch * 0.72; // sale claramente del agua!
    } else if (_failAnim > 0) {
      targetX = _simWidth * 0.22;
      targetY = _simHeight * 0.68;
      targetZ = 0.18;
    } else if (c.isHiding) {
      if (c.isPeeking) {
        targetX = _simWidth * 0.64;
        targetY = _simHeight * 0.44;
        targetZ = 0.74;
      } else {
        targetX = _simWidth * 0.82;
        targetY = _simHeight * 0.34;
        targetZ = 0.12; // sumergido bajo la hoja de loto
      }
    } else if (c.isChecking) {
      targetX = _simWidth * (0.18 + (c.lookValue / 100.0) * 0.62);
      targetY = _simHeight * 0.62 + math.sin(_time * 1.8) * 6;
      targetZ = 0.94;
    } else {
      // Nado sereno en ocho dentro del estanque
      targetX = _simWidth * (0.48 + math.sin(_time * 0.55) * 0.26);
      targetY = _simHeight * (0.54 + math.sin(_time * 1.10) * 0.18);
      targetZ = 0.80 + math.sin(_time * 0.7) * 0.12;
    }

    _z += (targetZ - _z) * math.min(1.0, dt * (_successAnim > 0 ? 7.5 : 2.2));
    final breachBoost = _z > 1.0 ? (_z - 1.0) * 0.62 : 0.0;
    final currentScale = _baseScale * (0.86 + math.min(1.0, _z) * 0.18 + breachBoost);
    final segLen = 9.4 * currentScale;

    final head = _nodes[0];
    final dx = targetX - head.x;
    final dy = targetY - head.y;
    final distToTarget = math.sqrt(dx * dx + dy * dy);

    final desiredAngle = math.atan2(dy, dx);
    var diff = desiredAngle - _angle;
    while (diff > math.pi) {
      diff -= 2 * math.pi;
    }
    while (diff < -math.pi) {
      diff += 2 * math.pi;
    }

    const turnRate = 2.1;
    final maxTurn = turnRate * dt;
    final deltaAngle = diff.clamp(-maxTurn, maxTurn);
    _angle += deltaAngle;
    _turnVel = deltaAngle / dt;

    final turnEffort = math.min(1.0, diff.abs() * 0.9);
    // Velocidad calma y natural (fiel a PondEngine: phase += dt * (4.5 + ...))
    final baseSpeed = _failAnim > 0
        ? 110.0
        : (_successAnim > 0 ? 92.0 : (distToTarget < 14 ? 22.0 : 58.0));
    final speed = baseSpeed * (1.0 + turnEffort * 0.22);
    _phase += dt * (3.6 + turnEffort * 1.4 + (_successAnim > 0 ? 2.2 : 0.0));

    head.x = (head.x + math.cos(_angle) * speed * dt).clamp(18.0, _simWidth - 18.0);
    head.y = (head.y + math.sin(_angle) * speed * dt).clamp(18.0, _simHeight - 18.0);

    // Seguimiento rigido de nodos (sin ruido)
    for (int i = 1; i < _nodes.length; i++) {
      final prev = _nodes[i - 1];
      final curr = _nodes[i];
      final sdx = curr.x - prev.x;
      final sdy = curr.y - prev.y;
      final d = math.max(0.0001, math.sqrt(sdx * sdx + sdy * sdy));
      curr.x = prev.x + (sdx / d) * segLen;
      curr.y = prev.y + (sdy / d) * segLen;
    }

    _rebuildRenderSpine(currentScale);

    if ((_time * 60).round() % 58 == 0) {
      _spawnRipple(
        head.x / _simWidth,
        head.y / _simHeight,
        const Color(0xFF5EEAD4),
        maxRadius: 10.5,
      );
    }

    for (final r in _ripples) {
      r.progress += dt * 0.80;
    }
    _ripples.removeWhere((r) => r.progress >= 1.0);

    // Fisica de gotas de salpicadura (gravedad + onda al aterrizar)
    for (final d in _splashDrops) {
      d.x += d.vx * dt;
      d.y += d.vy * dt;
      d.vz -= 1.65 * dt;
      d.z += d.vz * dt;
    }
    _splashDrops.removeWhere((d) {
      if (d.z <= 0.0) {
        if (d.x > 0.05 && d.x < 0.95 && d.y > 0.05 && d.y < 0.95) {
          _spawnRipple(d.x, d.y, d.color, maxRadius: 6.0);
        }
        return true;
      }
      return false;
    });

    setState(() {});
  }

  /// Exacto a PondEngine.swift lineas 887-905: ondulacion suave sin(phase - t * 6.5)
  void _rebuildRenderSpine(double scale) {
    final rNodes = List<_RenderNode>.filled(
      _nodeCount,
      const _RenderNode(0, 0, 0, 1),
    );
    for (int i = 0; i < _nodeCount; i++) {
      final t = i / (_nodeCount - 1);
      final prev = _nodes[math.max(0, i - 1)];
      final next = _nodes[math.min(_nodeCount - 1, i + 1)];
      var tx = prev.x - next.x;
      var ty = prev.y - next.y;
      final len = math.max(0.0001, math.sqrt(tx * tx + ty * ty));
      tx /= len;
      ty /= len;
      final nx = -ty;
      final ny = tx;
      // Ondulacion suave creciente hacia la cola (PondEngine: 1.1 + 20 * t^1.95)
      final amp = (0.9 + 16.5 * math.pow(t, 1.95)) * scale;
      final sway = math.sin(_phase - t * 6.5) * amp;
      rNodes[i] = _RenderNode(
        _nodes[i].x + nx * sway,
        _nodes[i].y + ny * sway,
        nx,
        ny,
      );
    }

    final segs = List<_SpineSeg>.generate(_nodeCount - 1, (i) {
      final a = rNodes[i];
      final b = rNodes[i + 1];
      final abx = b.x - a.x;
      final aby = b.y - a.y;
      final lenSq = math.max(0.0001, abx * abx + aby * aby);
      return _SpineSeg(
        ax: a.x,
        ay: a.y,
        abx: abx,
        aby: aby,
        invLenSq: 1.0 / lenSq,
        anx: a.nx,
        any: a.ny,
        dnx: b.nx - a.nx,
        dny: b.ny - a.ny,
      );
    });

    _renderNodes = rNodes;
    _segs = segs;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breachBoost = _z > 1.0 ? (_z - 1.0) * 0.34 : 0.0;
    final currentScale = _baseScale * (0.86 + math.min(1.0, _z) * 0.18 + breachBoost);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1717),
          border: Border.all(color: const Color(0xFF1E3A3A), width: 1.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: CustomPaint(
          painter: _AsciiKoiPondPainter(
            rows: _rows,
            simWidth: _simWidth,
            simHeight: _simHeight,
            time: _time,
            phase: _phase,
            turnVel: _turnVel,
            koiZ: _z,
            koiScale: currentScale,
            renderNodes: _renderNodes,
            segs: _segs,
            successAnim: _successAnim,
            failAnim: _failAnim,
            ripples: _ripples,
            splashDrops: _splashDrops,
            bubbles: _bubbles,
            statusLabel: _buildStatusLabel(),
          ),
        ),
      ),
    );
  }

  String _buildStatusLabel() {
    if (_successAnim > 0) return '> ¡Bienvenido a Ja’Map!';
    if (_failAnim > 0) return '> Credenciales incorrectas...';
    if (widget.controller.isHiding) {
      return widget.controller.isPeeking
          ? '> Asomándose desde el loto...'
          : '> Protegiendo tu contraseña';
    }
    if (widget.controller.isChecking) return '> Siguiendo tu correo...';
    return '> Ja’Map · El mapa del agua';
  }
}

class _AsciiCell {
  String ch;
  Color color;

  _AsciiCell(this.ch, this.color);
}

class _SpineProj {
  final double t;
  final double lat;
  final double dist;
  final double nx;
  final double ny;
  final bool outOfBounds;

  const _SpineProj(this.t, this.lat, this.dist, this.nx, this.ny, this.outOfBounds);
}

class _AsciiKoiPondPainter extends CustomPainter {
  final int rows;
  final double simWidth;
  final double simHeight;
  final double time;
  final double phase;
  final double turnVel;
  final double koiZ;
  final double koiScale;
  final List<_RenderNode> renderNodes;
  final List<_SpineSeg> segs;
  final double successAnim;
  final double failAnim;
  final List<_Ripple> ripples;
  final List<_SplashDrop> splashDrops;
  final List<_Bubble> bubbles;
  final String statusLabel;

  // Rampas exactas de PondEngine.swift
  static const String _shadeRamp = ' .,:;+*oO08@#';
  static const String _scaleRamp = ' .,:;coO08@#';
  static const String _finRamp = ' .,:~-=+*#';

  static const Color _bgColor = Color(0xFF0A1717);
  static const Color _shadowColor = Color(0xFF050D0D);
  static const Color _waterDim = Color(0xFF152C2B);
  static const Color _waterLight = Color(0xFF1F4240);
  static const Color _stoneColor = Color(0xFF193331);

  // Paleta Showa de PondEngine.swift
  static const Color _koiWhite = Color(0xFFF0F4F8);
  static const Color _koiHi = Color(0xFFEA580C);
  static const Color _koiGold = Color(0xFFF59E0B);
  static const Color _koiSumi = Color(0xFF28303E);
  static const Color _koiFin = Color(0xFFECDAD0);
  static const Color _koiFinDark = Color(0xFF3E4856);
  static const Color _koiBarbel = Color(0xFFFCE8D2);

  static const Color _lilyDark = Color(0xFF1D4D33);
  static const Color _lilyMid = Color(0xFF2E7D4F);
  static const Color _lilyLight = Color(0xFF4ADE80);
  static const Color _lotusPink = Color(0xFFF472B6);
  static const Color _lotusCore = Color(0xFFFDE047);

  _AsciiKoiPondPainter({
    required this.rows,
    required this.simWidth,
    required this.simHeight,
    required this.time,
    required this.phase,
    required this.turnVel,
    required this.koiZ,
    required this.koiScale,
    required this.renderNodes,
    required this.segs,
    required this.successAnim,
    required this.failAnim,
    required this.ripples,
    required this.splashDrops,
    required this.bubbles,
    required this.statusLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _bgColor);

    final cellH = (size.height - 20) / rows;
    final fontSize = cellH * 0.96;
    final cols = ((size.width - 8) / (fontSize * 0.68)).floor().clamp(58, 150);
    final cellW = (size.width - 8) / cols;

    final baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier New', 'Courier'],
      fontSize: fontSize,
      height: 1.0,
      fontWeight: FontWeight.w600,
    );

    // 1. Agua de fondo
    final grid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => _waterBackgroundCell(c, r)),
    );

    // 2. Piedras en el fondo
    _stampPebble(grid, cols, (cols * 0.16).round(), 19, 7, 3);
    _stampPebble(grid, cols, (cols * 0.52).round(), 6, 7, 2);
    _stampPebble(grid, cols, (cols * 0.87).round(), 19, 8, 3);

    // 3. Burbujas ascendentes
    for (final b in bubbles) {
      final cycle = (time * 0.35 + b.phase) % 1.0;
      final bc = (b.x * cols + math.sin(time * 2 + b.phase) * 1.1).round();
      final br = (b.y * rows - cycle * 5.0).round();
      final glyph = cycle < 0.35 ? '.' : (cycle < 0.75 ? 'o' : '°');
      _put(grid, cols, bc, br, glyph, const Color(0xFF5EEAD4).withValues(alpha: 0.65));
    }

    // 4. Pez Koi muestreado con proyeccion exacta de PondEngine.swift
    _sampleAndDrawKoi(grid, cols);

    // 5. Ondas (ripples)
    for (final r in ripples) {
      final cx = r.x * cols;
      final cy = r.y * rows;
      final rad = 2.0 + r.progress * r.maxRadius;
      final alpha = (1.0 - r.progress).clamp(0.0, 1.0);
      final glyph = r.progress < 0.35 ? 'o' : (r.progress < 0.7 ? '~' : ':');
      final rippleColor = r.color.withValues(alpha: alpha * 0.80);

      for (int step = 0; step < 30; step++) {
        final a = (step / 30.0) * 2 * math.pi;
        final gx = (cx + math.cos(a) * rad * 1.35).round();
        final gy = (cy + math.sin(a) * rad * 0.60).round();
        _put(grid, cols, gx, gy, glyph, rippleColor);
      }
    }

    // 6. Hojas de loto en primer plano
    _drawAsciiLilyPad(
      grid,
      cols,
      (cols * 0.82).round(),
      8,
      12.0,
      6.4,
      notchAngle: 2.35,
      withLotus: true,
    );
    _drawAsciiLilyPad(
      grid,
      cols,
      (cols * 0.13).round(),
      4,
      7.4,
      4.0,
      notchAngle: 0.6,
      withLotus: false,
    );

    // 6b. Gotas en el aire durante el salto (por encima de las hojas de loto)
    for (final d in splashDrops) {
      final dc = (d.x * cols).round();
      final dr = ((d.y - d.z * 0.35) * rows).round();
      final glyph = d.z > 0.18 ? '*' : (d.z > 0.08 ? 'o' : '·');
      _put(grid, cols, dc, dr, glyph, d.color);
    }

    // 7. Dibujo por celda exacta con cache de TextPainter
    final glyphCache = <String, TextPainter>{};
    for (int r = 0; r < rows; r++) {
      final y = r * cellH + 2;
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (cell.ch == ' ') continue;
        final key = '${cell.ch}_${cell.color.toARGB32()}';
        final tp = glyphCache.putIfAbsent(key, () {
          return TextPainter(
            text: TextSpan(
              text: cell.ch,
              style: baseStyle.copyWith(color: cell.color),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
        });
        final dx = 4 + c * cellW + (cellW - tp.width) / 2;
        tp.paint(canvas, Offset(dx, y));
      }
    }

    // 8. Barra inferior estilo terminal
    final statusPainter = TextPainter(
      text: TextSpan(
        text: statusLabel,
        style: TextStyle(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Menlo', 'Courier New'],
          color: successAnim > 0
              ? const Color(0xFF4ADE80)
              : (failAnim > 0 ? const Color(0xFFFB923C) : const Color(0xFF7DD3FC)),
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    statusPainter.paint(
      canvas,
      Offset(10, size.height - statusPainter.height - 4),
    );
  }

  /// Exacto a PondEngine.swift lineas 620-633
  double _bodyHalfWidth(double t, double s) {
    if (t < 0 || t > 0.76) return 0;
    final u = t / 0.76;
    final double w;
    if (u < 0.08) {
      w = 0.44 * math.pow(math.sin((u / 0.08) * (math.pi / 2)), 0.55);
    } else if (u < 0.30) {
      w = 0.44 + 0.56 * math.sin(((u - 0.08) / 0.22) * (math.pi / 2));
    } else {
      w = 0.115 + 0.885 * math.pow(1.0 - (u - 0.30) / 0.70, 1.52);
    }
    final eyeBulge = math.exp(-math.pow((t - 0.082) / 0.018, 2)) * 0.075;
    return (w + eyeBulge) * 26.5 * s;
  }

  _SpineProj _projectToSpine(double px, double py) {
    var bestDistSq = double.infinity;
    var bestT = 0.0;
    var bestLat = 0.0;
    var bestNx = 0.0;
    var bestNy = 1.0;
    var bestOutOfBounds = false;

    final nMinus1 = segs.length.toDouble();
    for (int i = 0; i < segs.length; i++) {
      final seg = segs[i];
      final rawU = ((px - seg.ax) * seg.abx + (py - seg.ay) * seg.aby) * seg.invLenSq;
      final u = rawU.clamp(0.0, 1.0);
      final cx = seg.ax + seg.abx * u;
      final cy = seg.ay + seg.aby * u;
      final dx = px - cx;
      final dy = py - cy;
      final dSq = dx * dx + dy * dy;
      if (dSq < bestDistSq) {
        bestDistSq = dSq;
        bestT = (i + u) / nMinus1;
        final nx = seg.anx + seg.dnx * u;
        final ny = seg.any + seg.dny * u;
        bestNx = nx;
        bestNy = ny;
        bestLat = dx * nx + dy * ny;
        bestOutOfBounds = (i == 0 && rawU < -0.15) || (i == segs.length - 1 && rawU > 1.05);
      }
    }
    return _SpineProj(bestT, bestLat, math.sqrt(bestDistSq), bestNx, bestNy, bestOutOfBounds);
  }

  void _sampleAndDrawKoi(List<List<_AsciiCell>> grid, int cols) {
    if (renderNodes.isEmpty || segs.isEmpty) return;

    // Bounding box del Koi en espacio de simulacion para muestrear solo las celdas necesarias
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;
    for (final n in renderNodes) {
      if (n.x < minX) minX = n.x;
      if (n.x > maxX) maxX = n.x;
      if (n.y < minY) minY = n.y;
      if (n.y > maxY) maxY = n.y;
    }
    final pad = 74.0 * koiScale;
    final minCol = (((minX - pad) / simWidth) * cols).floor().clamp(0, cols - 1);
    final maxCol = (((maxX + pad) / simWidth) * cols).ceil().clamp(0, cols - 1);
    final minRow = (((minY - pad) / simHeight) * rows).floor().clamp(0, rows - 1);
    final maxRow = (((maxY + pad) / simHeight) * rows).ceil().clamp(0, rows - 1);

    final depthTint = (1.0 - koiZ.clamp(0.0, 1.0)) * 0.65;
    Color applyDepth(Color c) => Color.lerp(c, const Color(0xFF102827), depthTint)!;

    final shadowOffX = 11.0 * koiScale * (0.4 + koiZ.clamp(0.0, 1.2) * 0.7);
    final shadowOffY = 13.0 * koiScale * (0.4 + koiZ.clamp(0.0, 1.2) * 0.7);

    // 1. Pasada de sombra suave debajo del pez
    for (int r = minRow; r <= maxRow; r++) {
      final py = ((r + 0.5) / rows) * simHeight - shadowOffY;
      for (int c = minCol; c <= maxCol; c++) {
        final px = ((c + 0.5) / cols) * simWidth - shadowOffX;
        final hit = _sampleKoiCell(px, py, shadowOnly: true, applyDepth: applyDepth);
        if (hit != null) {
          grid[r][c] = hit;
        }
      }
    }

    // 2. Pasada principal del Koi (cuerpo, aletas pectorales, pelvicas, caudal, ojos)
    for (int r = minRow; r <= maxRow; r++) {
      final py = ((r + 0.5) / rows) * simHeight;
      for (int c = minCol; c <= maxCol; c++) {
        final px = ((c + 0.5) / cols) * simWidth;
        final hit = _sampleKoiCell(px, py, shadowOnly: false, applyDepth: applyDepth);
        if (hit != null) {
          grid[r][c] = hit;
        }
      }
    }

    // 3. Dos bigotes (barbels) delicados delante de la nariz
    final r0 = renderNodes[0];
    final r1 = renderNodes[1];
    final headAngle = math.atan2(r0.y - r1.y, r0.x - r1.x);
    final barbelColor = applyDepth(_koiBarbel);
    for (final side in [-1.0, 1.0]) {
      final a = headAngle + side * 0.65;
      final bx = r0.x + math.cos(a) * (10.5 * koiScale);
      final by = r0.y + math.sin(a) * (10.5 * koiScale);
      final gc = ((bx / simWidth) * cols).round();
      final gr = ((by / simHeight) * rows).round();
      _put(grid, cols, gc, gr, side < 0 ? '~' : ',', barbelColor);
    }

    // 4. Chispas en salto de exito
    if (successAnim > 0.2) {
      final hx = (r0.x / simWidth) * cols;
      final hy = (r0.y / simHeight) * rows;
      for (int k = 0; k < 8; k++) {
        final a = time * 8 + k * math.pi / 4;
        _put(
          grid,
          cols,
          (hx + math.cos(a) * 7.5).round(),
          (hy + math.sin(a) * 3.8).round(),
          k.isEven ? '*' : '+',
          const Color(0xFF4ADE80),
        );
      }
    }
  }

  /// Portado directo de `sampleKoi` en PondEngine.swift (lineas 1245-1372).
  _AsciiCell? _sampleKoiCell(
    double px,
    double py, {
    required bool shadowOnly,
    required Color Function(Color) applyDepth,
  }) {
    final proj = _projectToSpine(px, py);
    if (proj.outOfBounds || proj.dist > 72 * koiScale) return null;
    final t = proj.t;
    final lat = proj.lat;
    final absLat = lat.abs();
    final s = koiScale;

    // A. Cuerpo principal (t: 0..0.76)
    if (t >= 0.0 && t <= 0.76) {
      final bw = _bodyHalfWidth(t, s);
      if (absLat <= bw) {
        if (shadowOnly) return _AsciiCell(':', _shadowColor);

        final normLat = bw > 0.01 ? lat / bw : 0.0;
        final z = math.sqrt(math.max(0.02, 1.0 - normLat * normLat));

        // Ojos con brillo (PondEngine lineas 1256-1262)
        const eyeT = 0.082;
        final eyeLat = _bodyHalfWidth(eyeT, s) * 0.80;
        final dEye = math.sqrt(
          math.pow((t - eyeT) * 265 * s, 2) + math.pow(absLat - eyeLat, 2),
        );
        if (dEye < 4.2 * s) {
          final isGlint = dEye < 1.8 * s;
          return _AsciiCell(
            isGlint ? '*' : '@',
            applyDepth(isGlint ? Colors.white : const Color(0xFF020617)),
          );
        }

        // Iluminacion 3D + causticas
        var shade = (proj.nx * normLat * 0.9) * -0.50 +
            (proj.ny * normLat * 0.9) * -0.56 +
            z * 0.66;
        shade = (0.32 + shade * 0.74).clamp(0.16, 1.0);

        // Branquias sutiles (gill seam)
        final gillCurve = 0.188 - 0.032 * (1.0 - normLat * normLat);
        final isGill = (t - gillCurve).abs() < 0.012 && absLat > bw * 0.28;
        if (isGill) shade *= 0.55;

        // Borde de escamas (diamond scales)
        var isScaleEdge = false;
        if (t > 0.195 && t < 0.74) {
          final scaleRow = t * 44;
          final stagger = (scaleRow.floor() % 2 == 0) ? 0.0 : 0.5;
          final su = scaleRow - scaleRow.floor();
          final sv = ((normLat * 4.5 + 12.0 + stagger) % 1.0);
          final dScale = math.sqrt(math.pow(su - 0.5, 2) + math.pow(sv - 0.5, 2));
          if (dScale > 0.37 && dScale < 0.52) {
            shade = math.max(0.14, shade - 0.12);
            isScaleEdge = true;
          } else if (dScale < 0.20) {
            shade = math.min(1.0, shade + 0.08);
          }
        }

        // Aleta dorsal ondulante sobre el lomo
        var isDorsal = false;
        if (t >= 0.29 && t <= 0.66) {
          final df = (t - 0.29) / 0.37;
          final dorsalOffset =
              math.sin(phase - t * 7.0 - 1.0) * (4.2 * s * math.sin(df * math.pi));
          final dorsalThick = (2.3 * s) * (0.4 + 0.6 * math.sin(df * math.pi));
          if ((lat - dorsalOffset).abs() < dorsalThick) {
            isDorsal = true;
            shade = math.min(1.0, shade + 0.16);
          }
        }

        final ramp = isScaleEdge ? _scaleRamp : _shadeRamp;
        final idx = (shade * (ramp.length - 1)).round().clamp(1, ramp.length - 1);
        var ch = ramp[idx];
        if (isDorsal) ch = idx > 9 ? 'W' : '+';
        if (isGill) ch = ';';

        final baseColor = _getPigmentColor(t, normLat);
        final shadedColor = Color.lerp(const Color(0xFF0A1717), baseColor, 0.45 + shade * 0.55)!;
        return _AsciiCell(ch, applyDepth(shadedColor));
      }
    }

    // B. Cola bifurcada (Caudal Fin, PondEngine lineas 1320-1336)
    if (t >= 0.71 && t <= 1.0) {
      final v = (t - 0.71) / 0.29;
      final tailWhip = math.sin(phase - 6.5 - v * 2.5) * (8.5 * v * v * s);
      final absEff = (lat - tailWhip).abs();
      final tailOuter = (3.8 + 31.5 * math.pow(v, 0.76)) * s;
      final notchInner =
          v > 0.36 ? math.pow((v - 0.36) / 0.64, 1.15) * 18.0 * s : -1.0;

      if (absEff <= tailOuter && absEff >= notchInner) {
        if (shadowOnly) return _AsciiCell('.', _shadowColor);
        final rayFrac = absEff / math.max(0.01, tailOuter);
        final ray = 0.5 + 0.5 * math.sin(rayFrac * 26 - v * 3.0);
        final spine = rayFrac > 0.88 && v < 0.78;
        final density = spine ? 0.90 : (1.0 - v * 0.64) * (0.36 + 0.64 * ray);
        final idx = (density * _finRamp.length).floor().clamp(1, _finRamp.length - 1);
        final ch = spine ? '=' : _finRamp[idx];
        final isDark = v < 0.55 && math.sin(rayFrac * 10 + 1.7) > 0.55;
        return _AsciiCell(ch, applyDepth(isDark ? _koiFinDark : _koiFin));
      }
    }

    // C. Aletas pectorales con remo MUY sutil (PondEngine lineas 1338-1358)
    // rowL/rowR apenas oscilan +/-0.022 en t, evitando el aleteo exagerado!
    final turnFlare = (turnVel * 0.018).clamp(-0.035, 0.035);
    final rowL = math.sin(phase * 0.55) * 0.020 + turnFlare;
    final rowR = math.sin(phase * 0.55 + 0.38) * 0.020 - turnFlare;
    final tStartP = 0.18 + (lat > 0 ? rowL : rowR);
    final tEndP = 0.46 + (lat > 0 ? rowL : rowR);

    if (t >= tStartP && t <= tEndP) {
      final f = (t - tStartP) / (tEndP - tStartP);
      final bw = _bodyHalfWidth(t, s);
      final reach = 34.0 * s * math.sin(math.pow(f, 0.58) * math.pi);
      final innerCut =
          f > 0.55 ? bw + ((f - 0.55) / 0.45) * 12 * s : bw * 0.88;
      if (absLat > innerCut && absLat <= bw + reach) {
        if (shadowOnly) return _AsciiCell('.', _shadowColor);
        final distFromBody = (absLat - bw) / math.max(0.01, reach);
        final ray = 0.5 + 0.5 * math.sin(f * 22 - distFromBody * 5.2);
        final spine = f < 0.13 && distFromBody < 0.92;
        final density = spine ? 0.92 : (1.0 - distFromBody * 0.62) * (0.38 + 0.62 * ray);
        final idx = (density * _finRamp.length).floor().clamp(1, _finRamp.length - 1);
        final ch = spine ? '=' : _finRamp[idx];
        final isDark = distFromBody < 0.42 && f > 0.12 && f < 0.70;
        return _AsciiCell(ch, applyDepth(isDark ? _koiFinDark : _koiFin));
      }
    }

    // D. Aletas pelvicas (PondEngine lineas 1360-1370)
    if (t >= 0.46 && t <= 0.62) {
      final f = (t - 0.46) / 0.16;
      final bw = _bodyHalfWidth(t, s);
      final reach = 15.0 * s * math.sin(math.pow(f, 0.68) * math.pi);
      if (absLat > bw * 0.88 && absLat <= bw + reach) {
        if (shadowOnly) return _AsciiCell('.', _shadowColor);
        final distFromBody = (absLat - bw) / math.max(0.01, reach);
        final density = (1.0 - distFromBody * 0.68) * 0.62;
        final idx = (density * _finRamp.length).floor().clamp(1, _finRamp.length - 1);
        return _AsciiCell(_finRamp[idx], applyDepth(_koiFin));
      }
    }

    return null;
  }

  /// Patron organico Showa (manchas fluidas de bermellon, dorado, perla y sumi).
  Color _getPigmentColor(double t, double normLat) {
    final wave1 = math.sin(t * 9.5 + 0.8) + 0.6 * math.cos(normLat * 3.1 - t * 4.0);
    final wave2 = math.sin(t * 13.0 - 2.1 + normLat * 2.4);
    if (t < 0.17 && normLat.abs() < 0.68) return _koiHi; // Tancho / corona roja
    if (wave2 > 0.85 && t > 0.22 && t < 0.72) return _koiSumi;
    if (wave1 > 0.35 && t < 0.68) return wave1 > 0.95 ? _koiHi : _koiGold;
    return _koiWhite;
  }

  _AsciiCell _waterBackgroundCell(int c, int r) {
    final wave = math.sin(c * 0.26 + time * 1.4 + r * 0.55);
    if (wave > 0.84) return _AsciiCell('~', _waterLight);
    if ((c + r) % 3 == 0) return _AsciiCell('·', _waterDim);
    if ((c * 5 + r * 3) % 13 == 0) return _AsciiCell(':', _waterDim);
    return _AsciiCell(' ', _bgColor);
  }

  void _stampPebble(List<List<_AsciiCell>> grid, int cols, int cx, int cy, int rx, int ry) {
    for (int r = cy - ry; r <= cy + ry; r++) {
      for (int c = cx - rx; c <= cx + rx; c++) {
        final nx = (c - cx) / rx;
        final ny = (r - cy) / ry;
        if (nx * nx + ny * ny <= 1.0) {
          _put(grid, cols, c, r, (c + r) % 2 == 0 ? ':' : '=', _stoneColor);
        }
      }
    }
  }

  void _drawAsciiLilyPad(
    List<List<_AsciiCell>> grid,
    int cols,
    int cx,
    int cy,
    double rx,
    double ry, {
    required double notchAngle,
    required bool withLotus,
  }) {
    for (int r = (cy - ry - 1).floor(); r <= (cy + ry + 1).ceil(); r++) {
      for (int c = (cx - rx - 1).floor(); c <= (cx + rx + 1).ceil(); c++) {
        final nx = (c - cx) / rx;
        final ny = (r - cy) / ry;
        final distSq = nx * nx + ny * ny;
        if (distSq <= 1.0) {
          final angle = math.atan2(ny, nx);
          var diff = (angle - notchAngle).abs();
          if (diff > math.pi) diff = 2 * math.pi - diff;
          if (diff < 0.24) continue;

          String glyph;
          Color color;
          if (distSq > 0.82) {
            glyph = ':';
            color = _lilyLight;
          } else if ((c + r) % 2 == 0) {
            glyph = '#';
            color = _lilyMid;
          } else {
            glyph = '%';
            color = _lilyDark;
          }
          _put(grid, cols, c, r, glyph, color);
        }
      }
    }

    if (withLotus) {
      final fx = cx + 3;
      final fy = cy - 1;
      _put(grid, cols, fx, fy, '@', _lotusCore);
      _put(grid, cols, fx - 1, fy, '#', _lotusPink);
      _put(grid, cols, fx + 1, fy, '#', _lotusPink);
      _put(grid, cols, fx, fy - 1, '*', _lotusPink);
      _put(grid, cols, fx, fy + 1, '*', _lotusPink);
      _put(grid, cols, fx - 2, fy, '+', const Color(0xFFFBCFE8));
      _put(grid, cols, fx + 2, fy, '+', const Color(0xFFFBCFE8));
      _put(grid, cols, fx - 1, fy - 1, '+', const Color(0xFFFBCFE8));
      _put(grid, cols, fx + 1, fy + 1, '+', const Color(0xFFFBCFE8));
    }
  }

  void _put(List<List<_AsciiCell>> grid, int cols, int c, int r, String ch, Color color) {
    if (r >= 0 && r < rows && c >= 0 && c < cols) {
      grid[r][c] = _AsciiCell(ch, color);
    }
  }

  @override
  bool shouldRepaint(covariant _AsciiKoiPondPainter oldDelegate) => true;
}
