import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Controlador imperativo del estanque Koi (analogo a los inputs de Rive:
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
  double x;
  double y;
  double progress = 0.0; // 0..1
  Color color;
  double maxRadius;

  _Ripple({
    required this.x,
    required this.y,
    required this.color,
    this.maxRadius = 48.0,
  });
}

class _Bubble {
  double x;
  double y;
  double radius;
  double phase;

  _Bubble(this.x, this.y, this.radius, this.phase);
}

/// Widget animado interactivo inspirado en ASCIIKoiSaver (estanque top-down con
/// pez Koi procedural, profundidad en eje Z bajo hoja de loto, burbujas y splashes).
class KoiPondLoginWidget extends StatefulWidget {
  final KoiPondController controller;
  final double height;

  const KoiPondLoginWidget({
    super.key,
    required this.controller,
    this.height = 195,
  });

  @override
  State<KoiPondLoginWidget> createState() => _KoiPondLoginWidgetState();
}

class _KoiPondLoginWidgetState extends State<KoiPondLoginWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  double _time = 0.0;
  double _koiX = 0.5;
  double _koiY = 0.54;
  double _koiAngle = -math.pi / 4;
  double _koiDepth = 0.15; // 0 = superficie, 1 = fondo bajo hoja de loto

  double _successAnim = 0.0; // >0 durante salto de exito
  double _failAnim = 0.0; // >0 durante susto de error
  int _lastSuccessTick = 0;
  int _lastFailTick = 0;

  final List<_Ripple> _ripples = [];
  final List<_Bubble> _bubbles = [
    _Bubble(0.22, 0.72, 2.5, 0.0),
    _Bubble(0.78, 0.34, 2.0, 1.8),
    _Bubble(0.36, 0.28, 1.8, 3.2),
    _Bubble(0.68, 0.76, 2.4, 4.7),
  ];

  @override
  void initState() {
    super.initState();
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
    if (widget.controller.successTick != _lastSuccessTick) {
      _lastSuccessTick = widget.controller.successTick;
      _successAnim = 1.0;
      _failAnim = 0.0;
      _spawnRipple(_koiX, _koiY, const Color(0xFF38BDF8), maxRadius: 72);
      _spawnRipple(_koiX, _koiY, const Color(0xFF4ADE80), maxRadius: 54);
    }
    if (widget.controller.failTick != _lastFailTick) {
      _lastFailTick = widget.controller.failTick;
      _failAnim = 1.0;
      _successAnim = 0.0;
      _spawnRipple(_koiX, _koiY, const Color(0xFFF97316), maxRadius: 64);
      _spawnRipple(_koiX, _koiY, const Color(0xFFEF4444), maxRadius: 46);
    }
  }

  void _spawnRipple(
    double nx,
    double ny,
    Color color, {
    double maxRadius = 46,
  }) {
    _ripples.add(_Ripple(x: nx, y: ny, color: color, maxRadius: maxRadius));
    if (_ripples.length > 12) {
      _ripples.removeAt(0);
    }
  }

  void _stepSimulation() {
    const dt = 1 / 60.0;
    _time += dt;

    final c = widget.controller;

    // Decaimiento de triggers
    if (_successAnim > 0) _successAnim = math.max(0.0, _successAnim - dt * 0.75);
    if (_failAnim > 0) _failAnim = math.max(0.0, _failAnim - dt * 1.15);

    // Determinar posicion objetivo y profundidad (eje Z) segun estado
    double targetX;
    double targetY;
    double targetDepth;

    if (_successAnim > 0) {
      // Salto en arco (surface breach) hacia el centro superior
      final arch = math.sin(_successAnim * math.pi);
      targetX = 0.5 + math.cos(_time * 6) * 0.06;
      targetY = 0.46 - arch * 0.14;
      targetDepth = -0.35 * arch; // sale ligeramente del agua
    } else if (_failAnim > 0) {
      // Retroceso asustado y zambullida rapida
      targetX = 0.24 + math.sin(_time * 28) * 0.03;
      targetY = 0.68;
      targetDepth = 0.85;
    } else if (c.isHiding) {
      // Se sumerge debajo de la hoja de loto (esquina superior derecha)
      if (c.isPeeking) {
        targetX = 0.67;
        targetY = 0.44;
        targetDepth = 0.35;
      } else {
        targetX = 0.78;
        targetY = 0.36;
        targetDepth = 0.92;
      }
    } else if (c.isChecking) {
      // Sigue suavemente la posicion horizontal del texto del correo (0..100)
      targetX = 0.18 + (c.lookValue / 100.0) * 0.64;
      targetY = 0.60 + math.sin(_time * 2.4) * 0.03;
      targetDepth = 0.08;
    } else {
      // Nado tranquilo en figura ocho dentro del estanque
      targetX = 0.48 + math.sin(_time * 0.75) * 0.22;
      targetY = 0.54 + math.sin(_time * 1.5) * 0.12;
      targetDepth = 0.20 + math.sin(_time * 0.9) * 0.10;
    }

    final dx = targetX - _koiX;
    final dy = targetY - _koiY;
    final speed = _failAnim > 0 ? 0.18 : (_successAnim > 0 ? 0.16 : 0.08);
    _koiX += dx * speed;
    _koiY += dy * speed;
    _koiDepth += (targetDepth - _koiDepth) * 0.10;

    if (dx.abs() + dy.abs() > 0.002) {
      final desiredAngle = math.atan2(dy, dx);
      var diff = desiredAngle - _koiAngle;
      while (diff > math.pi) {
        diff -= 2 * math.pi;
      }
      while (diff < -math.pi) {
        diff += 2 * math.pi;
      }
      _koiAngle += diff * 0.14;
    } else if (c.isChecking) {
      // Mira ligeramente hacia abajo (hacia el campo de texto)
      final desiredAngle = math.pi / 2 + ((c.lookValue - 50) / 100) * 0.55;
      _koiAngle += (desiredAngle - _koiAngle) * 0.12;
    }

    // Ondas ambientales suaves
    if ((_time * 60).round() % 55 == 0) {
      _spawnRipple(_koiX, _koiY, Colors.white.withValues(alpha: 0.45), maxRadius: 34);
    }

    for (final ripple in _ripples) {
      ripple.progress += dt * 0.85;
    }
    _ripples.removeWhere((r) => r.progress >= 1.0);

    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: CustomPaint(
          painter: _KoiPondPainter(
            time: _time,
            koiX: _koiX,
            koiY: _koiY,
            koiAngle: _koiAngle,
            koiDepth: _koiDepth,
            successAnim: _successAnim,
            failAnim: _failAnim,
            ripples: _ripples,
            bubbles: _bubbles,
            statusLabel: _buildStatusLabel(),
          ),
        ),
      ),
    );
  }

  String _buildStatusLabel() {
    if (_successAnim > 0) return '¡Bienvenido a Ja’Map!';
    if (_failAnim > 0) return 'Ups... revisa tus datos';
    if (widget.controller.isHiding) {
      return widget.controller.isPeeking ? 'Asomándose...' : 'Protegiendo tu contraseña';
    }
    if (widget.controller.isChecking) return 'Leyendo tu correo...';
    return 'Ja’Map · El mapa del agua';
  }
}

class _KoiPondPainter extends CustomPainter {
  final double time;
  final double koiX;
  final double koiY;
  final double koiAngle;
  final double koiDepth;
  final double successAnim;
  final double failAnim;
  final List<_Ripple> ripples;
  final List<_Bubble> bubbles;
  final String statusLabel;

  _KoiPondPainter({
    required this.time,
    required this.koiX,
    required this.koiY,
    required this.koiAngle,
    required this.koiDepth,
    required this.successAnim,
    required this.failAnim,
    required this.ripples,
    required this.bubbles,
    required this.statusLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo de estanque con gradiente profundo
    final pondPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF082F49),
          Color(0xFF0C4A6E),
          Color(0xFF0369A1),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, pondPaint);

    // 2. Piedras sumergidas en el lecho del estanque
    final stonePaint = Paint()..color = const Color(0xFF07253A).withValues(alpha: 0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.16, size.height * 0.78),
        width: 58,
        height: 32,
      ),
      stonePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.84, size.height * 0.72),
        width: 68,
        height: 36,
      ),
      stonePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.22),
        width: 48,
        height: 24,
      ),
      stonePaint,
    );

    // 3. Burbujas ascendentes estilo ASCIIKoiSaver
    final bubblePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.25);
    for (final b in bubbles) {
      final cycle = (time * 0.35 + b.phase) % 1.0;
      final bx = size.width * b.x + math.sin(time * 2 + b.phase) * 4;
      final by = size.height * b.y - cycle * 26;
      canvas.drawCircle(Offset(bx, by), b.radius * (0.6 + cycle * 0.6), bubblePaint);
    }

    // 4. Pez Koi procedural (sombra proporcional a profundidad Z + cuerpo articulado)
    _drawKoi(canvas, size);

    // 5. Ondas (ripples) en la superficie
    for (final r in ripples) {
      final alpha = (1.0 - r.progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * alpha + 0.5
        ..color = r.color.withValues(alpha: alpha * 0.75);
      canvas.drawCircle(
        Offset(r.x * size.width, r.y * size.height),
        6 + r.progress * r.maxRadius,
        paint,
      );
    }

    // 6. Hojas de loto (lily pads) en la superficie — el Koi se esconde debajo!
    _drawLilyPad(
      canvas,
      Offset(size.width * 0.80, size.height * 0.34),
      radius: 36,
      notchAngle: 2.35,
      color: const Color(0xFF15803D),
      hasFlower: true,
    );
    _drawLilyPad(
      canvas,
      Offset(size.width * 0.14, size.height * 0.28),
      radius: 22,
      notchAngle: 0.7,
      color: const Color(0xFF166534),
      hasFlower: false,
    );

    // 7. Etiqueta sutil inferior
    final textPainter = TextPainter(
      text: TextSpan(
        text: statusLabel,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(14, size.height - textPainter.height - 10),
    );
  }

  void _drawKoi(Canvas canvas, Size size) {
    final pos = Offset(koiX * size.width, koiY * size.height);
    final depthScale = (1.0 - koiDepth * 0.26).clamp(0.68, 1.22);
    final wagFreq = failAnim > 0 ? 22.0 : (successAnim > 0 ? 16.0 : 6.5);
    final wagAmp = failAnim > 0 ? 0.35 : 0.20;
    final tailWag = math.sin(time * wagFreq) * wagAmp;

    // Sombra en el lecho del estanque
    final shadowOffset = Offset(10 * (1.1 - koiDepth * 0.6), 14 * (1.1 - koiDepth * 0.6));
    canvas.save();
    canvas.translate(pos.dx + shadowOffset.dx, pos.dy + shadowOffset.dy);
    canvas.rotate(koiAngle);
    canvas.scale(depthScale);
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.24);
    canvas.drawOval(const Rect.fromLTWH(-24, -10, 44, 20), shadowPaint);
    canvas.restore();

    // Cuerpo del Koi
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(koiAngle);
    canvas.scale(depthScale);

    // Absorcion de color por profundidad (mas azulado al sumergirse)
    final waterTint = koiDepth.clamp(0.0, 1.0) * 0.55;
    Color applyDepth(Color c) => Color.lerp(c, const Color(0xFF0C4A6E), waterTint)!;

    // Aletas pectorales
    final finPaint = Paint()..color = applyDepth(const Color(0xFFFED7AA)).withValues(alpha: 0.85);
    final finFlutter = math.sin(time * wagFreq * 0.8) * 0.14;
    canvas.save();
    canvas.translate(4, -9);
    canvas.rotate(-0.45 + finFlutter);
    canvas.drawOval(const Rect.fromLTWH(-10, -4, 16, 8), finPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(4, 9);
    canvas.rotate(0.45 - finFlutter);
    canvas.drawOval(const Rect.fromLTWH(-10, -4, 16, 8), finPaint);
    canvas.restore();

    // Cola bifurcada con ondulacion
    canvas.save();
    canvas.translate(-22, 0);
    canvas.rotate(tailWag * 1.4);
    final tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-10, -10, -18, -12)
      ..quadraticBezierTo(-12, 0, -18, 12)
      ..quadraticBezierTo(-10, 10, 0, 0);
    canvas.drawPath(tailPath, Paint()..color = applyDepth(const Color(0xFFFFEDD5)));
    canvas.restore();

    // Segmento trasero del cuerpo
    canvas.save();
    canvas.translate(-10, 0);
    canvas.rotate(tailWag * 0.7);
    canvas.drawOval(
      const Rect.fromLTWH(-14, -7.5, 22, 15),
      Paint()..color = applyDepth(const Color(0xFFFFF7ED)),
    );
    canvas.restore();

    // Cuerpo principal (variedad Showa: blanco crema + manchas naranja Koi y negro sumi)
    final bodyPaint = Paint()..color = applyDepth(const Color(0xFFFFFBEB));
    canvas.drawOval(const Rect.fromLTWH(-16, -11, 36, 22), bodyPaint);

    // Manchas naranjas (Hi)
    final hiPaint = Paint()..color = applyDepth(const Color(0xFFEA580C));
    canvas.drawOval(const Rect.fromLTWH(2, -8, 13, 12), hiPaint);
    canvas.drawOval(const Rect.fromLTWH(-12, -3, 12, 10), hiPaint);

    // Mancha negra (Sumi)
    final sumiPaint = Paint()..color = applyDepth(const Color(0xFF1E293B));
    canvas.drawOval(const Rect.fromLTWH(-4, -9, 7, 6), sumiPaint);

    // Bigotes (barbels) del Koi
    final barbelPaint = Paint()
      ..color = applyDepth(const Color(0xFFFDBA74))
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(18, -4), Offset(24, -8 + tailWag * 4), barbelPaint);
    canvas.drawLine(const Offset(18, 4), Offset(24, 8 - tailWag * 4), barbelPaint);

    // Ojos
    final eyePaint = Paint()..color = applyDepth(const Color(0xFF0F172A));
    canvas.drawCircle(const Offset(14, -5.5), 1.8, eyePaint);
    canvas.drawCircle(const Offset(14, 5.5), 1.8, eyePaint);

    // Aleta dorsal sutil
    final dorsalPaint = Paint()
      ..color = applyDepth(Colors.white.withValues(alpha: 0.45))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(6, 0), Offset(-14, tailWag * 8), dorsalPaint);

    canvas.restore();
  }

  void _drawLilyPad(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double notchAngle,
    required Color color,
    required bool hasFlower,
  }) {
    // Sombra suave bajo la hoja
    canvas.drawCircle(
      center + const Offset(3, 5),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    // Hoja circular con muesca en V
    final rect = Rect.fromCircle(center: center, radius: radius);
    final padPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, notchAngle + 0.22, 2 * math.pi - 0.44, false)
      ..close();
    canvas.drawPath(padPath, Paint()..color = color);

    // Nervaduras sutiles
    final veinPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 6; i++) {
      final a = notchAngle + 0.6 + i * 0.9;
      canvas.drawLine(
        center,
        center + Offset(math.cos(a) * radius * 0.82, math.sin(a) * radius * 0.82),
        veinPaint,
      );
    }

    // Flor de loto pequeña
    if (hasFlower) {
      final flowerCenter = center + const Offset(8, -6);
      final petalPaint = Paint()..color = const Color(0xFFFBCFE8);
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 + math.sin(time) * 0.05;
        canvas.save();
        canvas.translate(flowerCenter.dx, flowerCenter.dy);
        canvas.rotate(angle);
        canvas.drawOval(const Rect.fromLTWH(0, -3.5, 11, 7), petalPaint);
        canvas.restore();
      }
      canvas.drawCircle(flowerCenter, 3.2, Paint()..color = const Color(0xFFFACC15));
    }
  }

  @override
  bool shouldRepaint(covariant _KoiPondPainter oldDelegate) => true;
}
