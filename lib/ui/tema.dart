// =============================================================================
// tema.dart — Solución A "El Pistón Clásico"
// Identidad visual: azul petróleo (confianza, taller serio) + naranja pistón
// (energía, llamadas a la acción). Fuente Barlow: sans-serif de inspiración
// industrial (señalética de carreteras), muy legible en pantallas pequeñas.
// =============================================================================
import 'package:flutter/material.dart';

import '../data/tablas.dart';

class Colores {
  static const azul = Color(0xFF12406B); // primario
  static const azulOscuro = Color(0xFF0B2A47);
  static const naranja = Color(0xFFFF8A00); // acento / acciones
  static const fondo = Color(0xFFF3F5F8);
  static const tarjeta = Color(0xFFFFFFFF);
  static const texto = Color(0xFF1B2430);
  static const textoSuave = Color(0xFF5F6B7A);
  static const exito = Color(0xFF2E7D32);
  static const peligro = Color(0xFFC62828);
  static const aviso = Color(0xFFEF6C00);
}

/// Color asociado a cada estado (se usa en chips, bordes y gráficos).
Color colorEstado(EstadoOrden e) => switch (e) {
      EstadoOrden.recibida => const Color(0xFF607D8B),
      EstadoOrden.diagnostico => const Color(0xFF1E88E5),
      EstadoOrden.reparacion => const Color(0xFFFF8A00),
      EstadoOrden.lista => const Color(0xFF2E7D32),
      EstadoOrden.entregada => const Color(0xFF455A64),
      EstadoOrden.cancelada => const Color(0xFFC62828),
    };

/// Icono asociado a cada estado (el color nunca es la única señal: accesibilidad).
IconData iconoEstado(EstadoOrden e) => switch (e) {
      EstadoOrden.recibida => Icons.inbox_outlined,
      EstadoOrden.diagnostico => Icons.search,
      EstadoOrden.reparacion => Icons.build_outlined,
      EstadoOrden.lista => Icons.check_circle_outline,
      EstadoOrden.entregada => Icons.directions_car_filled_outlined,
      EstadoOrden.cancelada => Icons.cancel_outlined,
    };

ThemeData temaClasico() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Colores.azul,
    primary: Colores.azul,
    secondary: Colores.naranja,
    surface: Colores.tarjeta,
    error: Colores.peligro,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    fontFamily: 'Barlow',
    scaffoldBackgroundColor: Colores.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.azul,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Barlow',
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Colores.naranja.withAlpha(60),
      labelTextStyle: WidgetStatePropertyAll(
        const TextStyle(fontFamily: 'Barlow', fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colores.naranja,
      foregroundColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colores.azul,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontFamily: 'Barlow', fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    chipTheme: const ChipThemeData(
      labelStyle: TextStyle(fontFamily: 'Barlow', fontWeight: FontWeight.w500),
    ),
  );
}
