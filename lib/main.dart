// =============================================================================
// main.dart — Punto de entrada de la Solución A "El Pistón Clásico".
// 1) Abre la base de datos local (Drift/SQLite).
// 2) Crea el repositorio con las reglas de negocio.
// 3) Lo inyecta en el árbol de widgets con TallerScope.
// 4) Configura MaterialApp: tema propio, idioma español y pantalla inicial.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/base_datos.dart';
import 'data/repositorio_taller.dart';
import 'data/taller_scope.dart';
import 'ui/shell.dart';
import 'ui/tema.dart';

void main() {
  // Necesario antes de usar plugins (path_provider/sqlite) en el arranque.
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final repo = RepositorioTaller(db);
  runApp(TallerScope(repo: repo, child: const ElPistonApp()));
}

class ElPistonApp extends StatelessWidget {
  const ElPistonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Pistón',
      debugShowCheckedModeBanner: false,
      theme: temaClasico(),
      // Español: textos de calendarios, botones de diálogos, etc.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Shell(),
    );
  }
}
