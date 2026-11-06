// =============================================================================
// shell.dart — Estructura de navegación principal de la Solución A.
// Barra de navegación inferior (NavigationBar de Material 3) con 5 secciones.
// Se usa IndexedStack para que cada pestaña conserve su estado (búsquedas,
// posición del scroll) al cambiar de una a otra.
// =============================================================================
import 'package:flutter/material.dart';

import 'pantallas/clientes.dart';
import 'pantallas/inicio.dart';
import 'pantallas/inventario.dart';
import 'pantallas/ordenes.dart';
import 'pantallas/reportes.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _indice = 0;

  /// Permite que el Inicio cambie de pestaña (p. ej. "ver órdenes").
  void irA(int i) => setState(() => _indice = i);

  @override
  Widget build(BuildContext context) {
    final paginas = <Widget>[
      InicioPantalla(irA: irA),
      const OrdenesPantalla(),
      const ClientesPantalla(),
      const InventarioPantalla(),
      const ReportesPantalla(),
    ];
    return Scaffold(
      body: IndexedStack(index: _indice, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: irA,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Órdenes'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Clientes'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventario'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reportes'),
        ],
      ),
    );
  }
}
