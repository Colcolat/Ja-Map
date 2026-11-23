import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../incidencias/screens/incidencias_screen.dart';
import '../utils/auth_validators.dart';
import '../widgets/koi_pond_login_widget.dart';
import 'sign_up_screen.dart';

/// Pantalla de inicio de sesion siguiendo OWASP con estetica oscura ASCII armonizada con el estanque Koi:
/// - Animacion de apertura con ola gradiente de agua desde la cual emergen los elementos.
/// - Campos con marco ASCII real a ancho completo (`+---[ CORREO ]---+` / `+===[ CORREO ]===+` al enfocar).
/// - Sin errorText ni validacion regex de complejidad en los campos (solo no vacios).
/// - Mensaje global unico "Credenciales inválidas" + animacion de fallo del Koi.
/// - Flujo de exito con CircularProgressIndicator, salto del Koi (surface breach) y Navigator.pushReplacement.
class LoginScreen extends StatefulWidget {
  final Future<void> Function(String email, String password)? onSignIn;
  final Future<void> Function(String email)? onSendPasswordReset;
  final WidgetBuilder? homeBuilder;
  final Duration successDelay;

  const LoginScreen({
    super.key,
    this.onSignIn,
    this.onSendPasswordReset,
    this.homeBuilder,
    this.successDelay = const Duration(milliseconds: 1650),
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Paleta armonizada con el estanque ASCII (#0A1717)
  static const Color _pondBg = Color(0xFF061010);
  static const Color _cardBg = Color(0xFF0B1C1C);
  static const Color _borderIdle = Color(0xFF234D4B);
  static const Color _borderFocus = Color(0xFF5EEAD4);
  static const Color _accentAqua = Color(0xFF5EEAD4);
  static const Color _accentJade = Color(0xFF0D9488);
  static const Color _accentGold = Color(0xFFF59E0B);
  static const Color _textLight = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF7FA6A4);

  late final AnimationController _introCtrl;
  final _koiController = KoiPondController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Timer? _typingDebounce;
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..forward();

    _emailFocusNode.addListener(() {
      setState(() {});
      if (_emailFocusNode.hasFocus) {
        _koiController.setHiding(false);
        _koiController.setChecking(true);
      } else {
        _typingDebounce?.cancel();
        _koiController.setChecking(false);
      }
    });

    _passwordFocusNode.addListener(() {
      setState(() {});
      final hasFocus = _passwordFocusNode.hasFocus;
      _koiController.setHiding(hasFocus);
      if (hasFocus) {
        _koiController.setPeeking(!_isObscure);
      }
    });
  }

  void _showInvalidCredentials() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Credenciales inválidas',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF991B1B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFF87171)),
          ),
        ),
      );
  }

  Future<void> _onLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _koiController.setChecking(false);
    _koiController.setHiding(false);

    // OWASP: en el login solo se valida que los campos no esten vacios.
    if (email.isEmpty || pass.isEmpty) {
      _koiController.trigFail();
      _showInvalidCredentials();
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.onSignIn != null) {
        await widget.onSignIn!(email, pass);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      // Salto del Koi (surface breach con gotas y ondas)
      _koiController.trigSuccess();
      await Future.delayed(widget.successDelay);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: widget.homeBuilder ?? (_) => const IncidenciasScreen(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _koiController.trigFail();
      _showInvalidCredentials();
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    String? dialogError;
    bool sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> enviarCorreo() async {
              final targetEmail = resetEmailCtrl.text.trim();
              if (!AuthValidators.isBasicEmail(targetEmail)) {
                setDialogState(() {
                  dialogError = 'Ingresa un correo electrónico válido.';
                });
                return;
              }

              setDialogState(() {
                dialogError = null;
                sending = true;
              });

              try {
                if (widget.onSendPasswordReset != null) {
                  await widget.onSendPasswordReset!(targetEmail);
                } else {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: targetEmail,
                  );
                }
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Se envió un correo de recuperación a $targetEmail.',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    backgroundColor: const Color(0xFF14532D),
                  ),
                );
              } catch (_) {
                setDialogState(() {
                  sending = false;
                  dialogError =
                      'No se pudo enviar el correo. Verifica tu conexión o correo.';
                });
              }
            }

            return AlertDialog(
              backgroundColor: _cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _borderIdle),
              ),
              title: const Text(
                '> Recuperar contraseña',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: _accentAqua,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu correo registrado y te enviaremos un enlace para restablecer tu contraseña.',
                    style: TextStyle(color: _textMuted, fontSize: 13.5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: _textLight, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      labelStyle: const TextStyle(color: _textMuted),
                      filled: true,
                      fillColor: _pondBg,
                      prefixIcon: const Icon(Icons.email_outlined, color: _accentAqua),
                      errorText: dialogError,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderIdle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderFocus),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: _textMuted, fontFamily: 'monospace'),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _accentJade),
                  onPressed: sending ? null : enviarCorreo,
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enviar',
                          style: TextStyle(fontFamily: 'monospace'),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    resetEmailCtrl.dispose();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _typingDebounce?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _koiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pondBg,
      body: Stack(
        children: [
          // Contenido principal emergiendo progresivamente tras la ola
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WaveRevealItem(
                    controller: _introCtrl,
                    start: 0.05,
                    end: 0.45,
                    child: KoiPondLoginWidget(controller: _koiController, height: 220),
                  ),
                  const SizedBox(height: 18),

                  _WaveRevealItem(
                    controller: _introCtrl,
                    start: 0.22,
                    end: 0.56,
                    child: const _AsciiSectionHeader(label: 'INICIAR SESIÓN'),
                  ),
                  const SizedBox(height: 16),

                  // Campo de correo con marco ASCII puro a ancho completo (SIN errorText por OWASP)
                  _WaveRevealItem(
                    controller: _introCtrl,
                    start: 0.34,
                    end: 0.68,
                    child: _AsciiInputBox(
                      label: 'CORREO',
                      focused: _emailFocusNode.hasFocus,
                      child: TextField(
                        controller: _emailCtrl,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: _textLight,
                          fontFamily: 'monospace',
                          fontSize: 14.5,
                        ),
                        cursorColor: _accentAqua,
                        onChanged: (value) {
                          _koiController.setChecking(true);
                          final look = (value.length / 40 * 100).clamp(0.0, 100.0);
                          _koiController.setLook(look);

                          _typingDebounce?.cancel();
                          _typingDebounce = Timer(const Duration(seconds: 3), () {
                            if (!mounted) return;
                            _koiController.setChecking(false);
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Correo electrónico',
                          hintStyle: TextStyle(
                            color: _textMuted,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: _accentAqua,
                            size: 19,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Campo de contraseña con marco ASCII puro a ancho completo (SIN errorText por OWASP)
                  _WaveRevealItem(
                    controller: _introCtrl,
                    start: 0.45,
                    end: 0.78,
                    child: _AsciiInputBox(
                      label: 'CLAVE',
                      focused: _passwordFocusNode.hasFocus,
                      child: TextField(
                        controller: _passCtrl,
                        focusNode: _passwordFocusNode,
                        obscureText: _isObscure,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          color: _textLight,
                          fontFamily: 'monospace',
                          fontSize: 14.5,
                        ),
                        cursorColor: _accentAqua,
                        onChanged: (_) => _koiController.setHiding(true),
                        onSubmitted: (_) => _isLoading ? null : _onLogin(),
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          hintStyle: const TextStyle(
                            color: _textMuted,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: _accentAqua,
                            size: 19,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure ? Icons.visibility : Icons.visibility_off,
                              color: _textMuted,
                              size: 19,
                            ),
                            onPressed: () {
                              setState(() => _isObscure = !_isObscure);
                              if (_passwordFocusNode.hasFocus) {
                                _koiController.setPeeking(!_isObscure);
                              }
                            },
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  _WaveRevealItem(
                    controller: _introCtrl,
                    start: 0.56,
                    end: 0.88,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _showForgotPasswordDialog,
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: _accentAqua,
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                decoration: TextDecoration.underline,
                                decorationColor: _accentAqua,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentJade,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: const BorderSide(color: _borderFocus, width: 1.2),
                              ),
                            ),
                            onPressed: _isLoading ? null : _onLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  _WaveRevealItem(
                    controller: _introCtrl,
                    start: 0.68,
                    end: 1.0,
                    child: Column(
                      children: [
                        const _AsciiFullLine(ch: '-', color: _borderIdle),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿No tienes cuenta?',
                              style: TextStyle(
                                color: _textMuted,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SignUpScreen(),
                                        ),
                                      );
                                    },
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: _accentGold,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _accentGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ola gradiente de agua de apertura (desaparece sola al terminar, nunca bloquea toques)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _introCtrl,
                builder: (context, _) {
                  if (_introCtrl.value >= 0.99) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    painter: _WaterWaveIntroPainter(progress: _introCtrl.value),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Anima la entrada escalonada de cada elemento como si emergiera de la ola.
class _WaveRevealItem extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final double end;
  final Widget child;

  const _WaveRevealItem({
    required this.controller,
    required this.start,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final v = curve.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1.0 - v) * 22),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Ola gradiente 100% ASCII que barre la pantalla al abrir la app revelando el Login.
class _WaterWaveIntroPainter extends CustomPainter {
  final double progress;

  _WaterWaveIntroPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeInOutCubic.transform(progress);
    final waveY = size.height * (eased * 1.28 - 0.10);
    final fade = (1.0 - ((progress - 0.72) / 0.28).clamp(0.0, 1.0));
    if (fade <= 0.01) return;

    const cellW = 10.5;
    const cellH = 14.0;
    final cols = (size.width / cellW).ceil();
    final rows = (size.height / cellH).ceil();

    // 1. Velo oscuro debajo de la cresta para que los elementos emerjan detras de la ola
    final maskPath = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 10) {
      final y = _crestAt(x, size.width, waveY);
      maskPath.lineTo(x, y);
    }
    maskPath
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      maskPath,
      Paint()..color = const Color(0xFF061010).withValues(alpha: 0.94 * fade),
    );

    // 2. Gradiente de caracteres ASCII desde la espuma luminosa hasta el fondo marino
    final style = const TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Courier New'],
      fontSize: 12,
      height: 1.0,
      fontWeight: FontWeight.w600,
    );
    final cache = <String, TextPainter>{};

    TextPainter glyph(String ch, Color color) {
      final key = '${ch}_${color.toARGB32()}';
      return cache.putIfAbsent(key, () {
        return TextPainter(
          text: TextSpan(text: ch, style: style.copyWith(color: color)),
          textDirection: TextDirection.ltr,
        )..layout();
      });
    }

    final cFoam = const Color(0xFFA5F3FC).withValues(alpha: 0.95 * fade);
    final cCrest = const Color(0xFF5EEAD4).withValues(alpha: 0.90 * fade);
    final cShallow = const Color(0xFF14B8A6).withValues(alpha: 0.78 * fade);
    final cMid = const Color(0xFF0E7490).withValues(alpha: 0.68 * fade);
    final cDeep = const Color(0xFF164E63).withValues(alpha: 0.50 * fade);
    final cAbyss = const Color(0xFF173130).withValues(alpha: 0.42 * fade);

    for (int c = 0; c < cols; c++) {
      final x = c * cellW;
      final crestY = _crestAt(x, size.width, waveY);
      final startRow = ((crestY - cellH) / cellH).floor().clamp(0, rows - 1);

      for (int r = startRow; r < rows; r++) {
        final y = r * cellH;
        final dy = y - crestY;

        String ch;
        Color color;
        if (dy < -2) {
          // Chispas de espuma justo encima de la cresta
          if ((c + (progress * 24).floor()) % 5 != 0) continue;
          ch = c.isEven ? '°' : '*';
          color = cFoam;
        } else if (dy < 14) {
          ch = (c + r).isEven ? '~' : '^';
          color = cCrest;
        } else if (dy < 36) {
          ch = (c % 3 == 0) ? '≈' : '~';
          color = cShallow;
        } else if (dy < 72) {
          ch = ((c + r) % 2 == 0) ? '=' : '-';
          color = cMid;
        } else if (dy < 120) {
          ch = ((c + r) % 3 == 0) ? '%' : ':';
          color = cDeep;
        } else {
          if ((c + r) % 2 != 0) continue;
          ch = ((c * 3 + r) % 5 == 0) ? '~' : '·';
          color = cAbyss;
        }

        final tp = glyph(ch, color);
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  double _crestAt(double x, double width, double waveY) {
    final nx = x / width;
    return waveY +
        math.sin(nx * math.pi * 2.5 + progress * 8.5) * 14 +
        math.cos(nx * math.pi * 4.2 - progress * 5.0) * 5;
  }

  @override
  bool shouldRepaint(covariant _WaterWaveIntroPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Linea ASCII que ocupa el 100% del ancho disponible sin cortes ni huecos.
class _AsciiFullLine extends StatelessWidget {
  final String ch;
  final Color color;

  const _AsciiFullLine({required this.ch, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      width: double.infinity,
      child: CustomPaint(
        painter: _AsciiLinePainter(ch: ch, color: color),
      ),
    );
  }
}

class _AsciiLinePainter extends CustomPainter {
  final String ch;
  final Color color;

  const _AsciiLinePainter({required this.ch, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const step = 8.0;
    final count = (size.width / step).floor();
    final tp = TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          fontFamily: 'monospace',
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    for (int i = 0; i < count; i++) {
      tp.paint(canvas, Offset(i * step + (step - tp.width) / 2, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _AsciiLinePainter oldDelegate) =>
      oldDelegate.ch != ch || oldDelegate.color != color;
}

/// Encabezado estilo terminal ASCII con lineas "===" a ancho completo.
class _AsciiSectionHeader extends StatelessWidget {
  final String label;

  const _AsciiSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _AsciiFullLine(ch: '=', color: Color(0xFF234D4B)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '[ $label ]',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF5EEAD4),
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(
          child: _AsciiFullLine(ch: '=', color: Color(0xFF234D4B)),
        ),
      ],
    );
  }
}

/// Caja de texto con marco 100% ASCII dibujado a ancho completo:
/// - En reposo: `+--[ LABEL ]--------------------+` con lados `|`
/// - En foco:   `+==[ LABEL ]====================+` con brillo agua `#5EEAD4`
class _AsciiInputBox extends StatelessWidget {
  final String label;
  final bool focused;
  final Widget child;

  const _AsciiInputBox({
    required this.label,
    required this.focused,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AsciiBoxFramePainter(label: label, focused: focused),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: child,
      ),
    );
  }
}

class _AsciiBoxFramePainter extends CustomPainter {
  final String label;
  final bool focused;

  const _AsciiBoxFramePainter({required this.label, required this.focused});

  @override
  void paint(Canvas canvas, Size size) {
    final borderColor = focused ? const Color(0xFF5EEAD4) : const Color(0xFF234D4B);
    final labelColor = focused ? const Color(0xFF5EEAD4) : const Color(0xFF7FA6A4);
    final bgColor = focused ? const Color(0xFF0D2323) : const Color(0xFF0A1A1A);
    final hChar = focused ? '=' : '-';
    final vChar = focused ? '║' : '|';
    final cornerChar = '+';

    // Fondo sutil dentro del marco ASCII
    canvas.drawRect(
      Rect.fromLTWH(5, 7, size.width - 10, size.height - 14),
      Paint()..color = bgColor,
    );

    final style = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier New'],
      color: borderColor,
      fontSize: 11.5,
      height: 1.0,
      fontWeight: FontWeight.w600,
    );

    TextPainter makeTp(String text, {Color? color}) {
      return TextPainter(
        text: TextSpan(text: text, style: color == null ? style : style.copyWith(color: color)),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    const stepX = 8.0;
    const stepY = 12.0;
    final cols = math.max(12, (size.width / stepX).floor());
    final rightX = (cols - 1) * stepX;
    final bottomY = size.height - 12;

    final cornerTp = makeTp(cornerChar);
    final hTp = makeTp(hChar);
    final vTp = makeTp(vChar);
    final labelTp = makeTp(' $label ', color: labelColor);

    // Esquinas
    cornerTp.paint(canvas, const Offset(0, 0));
    cornerTp.paint(canvas, Offset(rightX, 0));
    cornerTp.paint(canvas, Offset(0, bottomY));
    cornerTp.paint(canvas, Offset(rightX, bottomY));

    // Borde superior: +==[ LABEL ]==================+
    hTp.paint(canvas, const Offset(stepX, 0));
    hTp.paint(canvas, const Offset(stepX * 2, 0));
    final bracketL = makeTp('[', color: borderColor);
    final bracketR = makeTp(']', color: borderColor);
    var cursorX = stepX * 3;
    bracketL.paint(canvas, Offset(cursorX, 0));
    cursorX += bracketL.width;
    labelTp.paint(canvas, Offset(cursorX, 0));
    cursorX += labelTp.width;
    bracketR.paint(canvas, Offset(cursorX, 0));
    cursorX += bracketR.width + 2;

    for (double x = cursorX; x <= rightX - stepX; x += stepX) {
      hTp.paint(canvas, Offset(x, 0));
    }

    // Borde inferior completo
    for (int i = 1; i < cols - 1; i++) {
      hTp.paint(canvas, Offset(i * stepX, bottomY));
    }

    // Lados izquierdo y derecho
    for (double y = stepY; y <= bottomY - stepY * 0.7; y += stepY) {
      vTp.paint(canvas, Offset(1, y));
      vTp.paint(canvas, Offset(rightX + 1, y));
    }
  }

  @override
  bool shouldRepaint(covariant _AsciiBoxFramePainter oldDelegate) =>
      oldDelegate.focused != focused || oldDelegate.label != label;
}
