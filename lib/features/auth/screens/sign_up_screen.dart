import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/auth_validators.dart';

/// Pantalla de registro con validaciones por campo y reglas visibles de contrasena,
/// armonizada con la estetica oscura estanque/ASCII de Ja'Map.
class SignUpScreen extends StatefulWidget {
  final Future<void> Function(String email, String password)? onSignUp;

  const SignUpScreen({super.key, this.onSignUp});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const Color _pondBg = Color(0xFF061010);
  static const Color _cardBg = Color(0xFF0B1C1C);
  static const Color _borderIdle = Color(0xFF234D4B);
  static const Color _borderFocus = Color(0xFF5EEAD4);
  static const Color _accentAqua = Color(0xFF5EEAD4);
  static const Color _accentJade = Color(0xFF0D9488);
  static const Color _textLight = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF7FA6A4);
  static const Color _errorRed = Color(0xFFF87171);

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isObscurePass = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  String? _emailError;
  String? _passError;
  String? _confirmError;

  bool _validateFields() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    String? emailErr;
    String? passErr;
    String? confirmErr;

    if (email.isEmpty) {
      emailErr = 'Ingresa tu correo electrónico.';
    } else if (!AuthValidators.isBasicEmail(email)) {
      emailErr = 'Ingresa un correo electrónico válido.';
    }

    if (pass.isEmpty) {
      passErr = 'Ingresa una contraseña.';
    } else if (!AuthValidators.isStrongPassword(pass)) {
      passErr = 'La contraseña no cumple todas las reglas de seguridad.';
    }

    if (confirm.isEmpty) {
      confirmErr = 'Confirma tu contraseña.';
    } else if (confirm != pass) {
      confirmErr = 'Las contraseñas no coinciden.';
    }

    setState(() {
      _emailError = emailErr;
      _passError = passErr;
      _confirmError = confirmErr;
    });

    return emailErr == null && passErr == null && confirmErr == null;
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_validateFields()) return;

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    setState(() => _isLoading = true);

    try {
      if (widget.onSignUp != null) {
        await widget.onSignUp!(email, pass);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta creada correctamente. Ya puedes iniciar sesión.',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: Color(0xFF14532D),
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'email-already-in-use' => 'Ese correo ya tiene una cuenta registrada.',
        'invalid-email' => 'El formato del correo electrónico no es válido.',
        'weak-password' => 'La contraseña es demasiado débil para Firebase.',
        _ => 'No se pudo completar el registro. Intenta de nuevo.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: 'monospace')),
          backgroundColor: const Color(0xFF991B1B),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocurrió un error al registrar tu cuenta.',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _darkFieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _textMuted, fontFamily: 'monospace', fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFF4F7371), fontFamily: 'monospace', fontSize: 13),
      errorText: errorText,
      errorStyle: const TextStyle(color: _errorRed, fontFamily: 'monospace', fontSize: 11.5),
      prefixIcon: Icon(icon, color: _accentAqua, size: 19),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _cardBg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderIdle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderFocus, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorRed, width: 1.4),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pass = _passCtrl.text;

    return Scaffold(
      backgroundColor: _pondBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1717),
        foregroundColor: _textLight,
        title: const Text(
          '> Crear cuenta',
          style: TextStyle(
            fontFamily: 'monospace',
            color: _accentAqua,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderIdle),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '[ ÚNETE A JA’MAP ]',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: _accentAqua,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Crea tu cuenta con tu correo electrónico y una contraseña segura.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: _textMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Correo electrónico
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: _textLight, fontFamily: 'monospace', fontSize: 14),
                cursorColor: _accentAqua,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                decoration: _darkFieldDecoration(
                  label: 'Correo electrónico',
                  hint: 'ejemplo@correo.com',
                  icon: Icons.email_outlined,
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 14),

              // Contraseña
              TextField(
                controller: _passCtrl,
                obscureText: _isObscurePass,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: _textLight, fontFamily: 'monospace', fontSize: 14),
                cursorColor: _accentAqua,
                onChanged: (_) => setState(() => _passError = null),
                decoration: _darkFieldDecoration(
                  label: 'Contraseña',
                  hint: 'Mínimo 8 caracteres',
                  icon: Icons.lock_outline,
                  errorText: _passError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscurePass ? Icons.visibility : Icons.visibility_off,
                      color: _textMuted,
                      size: 19,
                    ),
                    onPressed: () {
                      setState(() => _isObscurePass = !_isObscurePass);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Reglas visibles de contraseña en vivo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderIdle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '+--[ REGLAS DE CONTRASEÑA ]--+',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: _accentAqua,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PasswordRuleRow(
                      label: 'Mínimo 8 caracteres',
                      met: AuthValidators.hasMinLength(pass),
                    ),
                    _PasswordRuleRow(
                      label: 'Al menos una letra mayúscula (A-Z)',
                      met: AuthValidators.hasUppercase(pass),
                    ),
                    _PasswordRuleRow(
                      label: 'Al menos una letra minúscula (a-z)',
                      met: AuthValidators.hasLowercase(pass),
                    ),
                    _PasswordRuleRow(
                      label: 'Al menos un número (0-9)',
                      met: AuthValidators.hasDigit(pass),
                    ),
                    _PasswordRuleRow(
                      label: 'Al menos un símbolo (!@#\$%&*)',
                      met: AuthValidators.hasSymbol(pass),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Confirmación de contraseña
              TextField(
                controller: _confirmPassCtrl,
                obscureText: _isObscureConfirm,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: _textLight, fontFamily: 'monospace', fontSize: 14),
                cursorColor: _accentAqua,
                onChanged: (_) {
                  if (_confirmError != null) setState(() => _confirmError = null);
                },
                onSubmitted: (_) => _isLoading ? null : _onSubmit(),
                decoration: _darkFieldDecoration(
                  label: 'Confirmar contraseña',
                  hint: 'Repite tu contraseña',
                  icon: Icons.lock_reset_outlined,
                  errorText: _confirmError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureConfirm ? Icons.visibility : Icons.visibility_off,
                      color: _textMuted,
                      size: 19,
                    ),
                    onPressed: () {
                      setState(() => _isObscureConfirm = !_isObscureConfirm);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentJade,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: _borderFocus, width: 1.2),
                    ),
                  ),
                  onPressed: _isLoading ? null : _onSubmit,
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
                          'Registrarme',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
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

class _PasswordRuleRow extends StatelessWidget {
  final String label;
  final bool met;

  const _PasswordRuleRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final color = met ? const Color(0xFF4ADE80) : const Color(0xFF7FA6A4);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
