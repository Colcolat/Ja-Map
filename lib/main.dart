import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const JaMapApp());
}

class JaMapApp extends StatelessWidget {
  final Widget? homeOverride;

  const JaMapApp({super.key, this.homeOverride});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ja’Map',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: homeOverride ??
          const Scaffold(
            body: Center(
              child: Text('Ja’Map — Base lista para Login y Catálogo'),
            ),
          ),
    );
  }
}
