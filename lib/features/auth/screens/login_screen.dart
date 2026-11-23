import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../incidencias/screens/incidencias_screen.dart';
import '../utils/auth_validators.dart';
import '../widgets/koi_pond_login_widget.dart';
import 'sign_up_screen.dart';

/// Pantalla de inicio de sesion siguiendo OWASP:
/// - Sin errorText ni validacion regex de complejidad en los campos (solo no vacios).
/// - Mensaje global unico "Credenciales inválidas" + animacion de fallo del Koi.
/// - Flujo de exito con CircularProgressIndicator, animacion de exito y Navigator.pushReplacement.
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
    this.successDelay = const Duration(milliseconds: 1400),
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        _koiController.setHiding(false);
        _koiController.setChecking(true);
      } else {
        _typingDebounce?.cancel();
        _koiController.setChecking(false);
      }
    });

    _passwordFocusNode.addListener(() {
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
          content: const Text('Credenciales inválidas'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
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
                    ),
                    backgroundColor: const Color(0xFF15803D),
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
              title: const Text('Recuperar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu correo registrado y te enviaremos un enlace para restablecer tu contraseña.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: dialogError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
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
                      : const Text('Enviar'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Estanque Koi interactivo inspirado en ASCIIKoiSaver
              KoiPondLoginWidget(controller: _koiController, height: 195),
              const SizedBox(height: 20),

              Text(
                'Iniciar sesión',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),

              // Campo de correo (SIN errorText por OWASP)
              TextField(
                controller: _emailCtrl,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
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
                  hintText: 'usuario@tecdesoftware.edu.mx',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Campo de contraseña (SIN errorText por OWASP)
              TextField(
                controller: _passCtrl,
                focusNode: _passwordFocusNode,
                obscureText: _isObscure,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _koiController.setHiding(true),
                onSubmitted: (_) => _isLoading ? null : _onLogin(),
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _isObscure = !_isObscure);
                      if (_passwordFocusNode.hasFocus) {
                        _koiController.setPeeking(!_isObscure);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _showForgotPasswordDialog,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 50,
                child: FilledButton(
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tienes cuenta?'),
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
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
