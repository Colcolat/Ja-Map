import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamap_app/features/auth/screens/login_screen.dart';
import 'package:jamap_app/features/auth/screens/sign_up_screen.dart';
import 'package:jamap_app/features/auth/utils/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('valida correo institucional @tecdesoftware.edu.mx', () {
      expect(
        AuthValidators.isInstitutionalEmail('juan.perez@tecdesoftware.edu.mx'),
        isTrue,
      );
      expect(
        AuthValidators.isInstitutionalEmail('JUAN@TECDESOFTWARE.EDU.MX'),
        isTrue,
      );
      expect(AuthValidators.isInstitutionalEmail('juan@gmail.com'), isFalse);
      expect(AuthValidators.isInstitutionalEmail('invalido'), isFalse);
    });

    test('valida las 5 reglas de contrasena fuerte', () {
      expect(AuthValidators.isStrongPassword('JaMap2026!'), isTrue);
      expect(AuthValidators.isStrongPassword('short1!A'), isTrue);
      expect(AuthValidators.isStrongPassword('jamap2026!'), isFalse); // sin mayuscula
      expect(AuthValidators.isStrongPassword('JAMAP2026!'), isFalse); // sin minuscula
      expect(AuthValidators.isStrongPassword('JaMapPass!'), isFalse); // sin digito
      expect(AuthValidators.isStrongPassword('JaMap2026'), isFalse); // sin simbolo
      expect(AuthValidators.isStrongPassword('Ja1!a'), isFalse); // < 8
    });
  });

  group('LoginScreen (OWASP)', () {
    testWidgets('campos vacios muestran mensaje global unico Credenciales inválidas', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Credenciales inválidas'), findsOneWidget);
    });

    testWidgets('error de autenticacion muestra Credenciales inválidas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            onSignIn: (_, _) async => throw Exception('invalid-credential'),
          ),
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'user@tecdesoftware.edu.mx');
      await tester.enterText(fields.at(1), 'wrongpass');
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Credenciales inválidas'), findsOneWidget);
    });

    testWidgets('login exitoso navega con pushReplacement al catalogo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            successDelay: Duration.zero,
            onSignIn: (_, _) async {},
            homeBuilder: (_) => const Scaffold(body: Text('Catalogo OK')),
          ),
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'user@tecdesoftware.edu.mx');
      await tester.enterText(fields.at(1), 'JaMap2026!');
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Catalogo OK'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('boton Sign up navega a SignUpScreen con Navigator.push', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SignUpScreen), findsOneWidget);
    });
  });

  group('SignUpScreen', () {
    testWidgets('rechaza correo no institucional y contrasena debil con errores por campo', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'usuario@gmail.com');
      await tester.enterText(fields.at(1), '12345');
      await tester.enterText(fields.at(2), '54321');

      await tester.ensureVisible(find.text('Registrarme'));
      await tester.tap(find.text('Registrarme'));
      await tester.pump();

      expect(
        find.textContaining('@tecdesoftware.edu.mx'),
        findsWidgets,
      );
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    });

    testWidgets('registra usuario valido y regresa al Login', (tester) async {
      String? registeredEmail;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignUpScreen(
                        onSignUp: (email, _) async {
                          registeredEmail = email;
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Ir a registro'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ir a registro'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'ana.pech@tecdesoftware.edu.mx');
      await tester.enterText(fields.at(1), 'JaMap2026!');
      await tester.enterText(fields.at(2), 'JaMap2026!');

      await tester.ensureVisible(find.text('Registrarme'));
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(registeredEmail, 'ana.pech@tecdesoftware.edu.mx');
      expect(find.text('Ir a registro'), findsOneWidget);
    });
  });
}
