import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/auth_validators.dart';

/// Pantalla de registro con validaciones por campo, reglas visibles de contrasena
/// y correo institucional obligatorio (@tecdesoftware.edu.mx).
class SignUpScreen extends StatefulWidget {
  final Future<void> Function(String email, String password)? onSignUp;

  const SignUpScreen({super.key, this.onSignUp});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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
      emailErr = 'Ingresa tu correo institucional.';
    } else if (!AuthValidators.isInstitutionalEmail(email)) {
      emailErr =
          'Usa un correo institucional terminado en ${AuthValidators.institutionalDomain}.';
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
          content: Text('Cuenta creada correctamente. Ya puedes iniciar sesión.'),
          backgroundColor: Color(0xFF15803D),
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
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ocurrió un error al registrar tu cuenta.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Únete a Ja’Map',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Regístrate con tu correo institucional (${AuthValidators.institutionalDomain}).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Correo institucional
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                decoration: InputDecoration(
                  labelText: 'Correo institucional',
                  hintText: 'nombre@tecdesoftware.edu.mx',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 14),

              // Contraseña
              TextField(
                controller: _passCtrl,
                obscureText: _isObscurePass,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _passError = null),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _passError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscurePass ? Icons.visibility : Icons.visibility_off,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu contraseña debe incluir:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
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
                onChanged: (_) {
                  if (_confirmError != null) setState(() => _confirmError = null);
                },
                onSubmitted: (_) => _isLoading ? null : _onSubmit(),
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  errorText: _confirmError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _isObscureConfirm = !_isObscureConfirm);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                height: 50,
                child: FilledButton(
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    final color = met ? const Color(0xFF15803D) : Colors.blueGrey.shade500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
