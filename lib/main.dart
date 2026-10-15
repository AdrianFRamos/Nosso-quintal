import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nosso_quintal/firebase_options.dart';
import 'package:nosso_quintal/screens/inicio.dart';
import 'package:nosso_quintal/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NossoQuintalApp());
}

class NossoQuintalApp extends StatelessWidget {
  const NossoQuintalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nosso Quintal',
      debugShowCheckedModeBanner: false,
      theme: temaNossoQuintal(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const InicioScreen(),
    );
  }
}
