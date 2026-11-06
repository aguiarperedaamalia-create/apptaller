// =============================================================================
// ordenes.dart — Lista de órdenes (Solución A).
// Filtros con FilterChip en una fila desplazable: Abiertas (por defecto),
// cada estado individual, o Todas. Búsqueda por matrícula, cliente o problema.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../../data/base_datos.dart';
import '../../data/taller_scope.dart';
import '../comun.dart';
import '../tema.dart';
import '../widgets/orden_tile.dart';
import 'orden_nueva.dart';

/// Opciones del filtro: null = abiertas; 'todas'; o un estado concreto.
class OrdenesPantalla extends StatefulWidget {
  const OrdenesPantalla({super.key});

  @override
  State<OrdenesPantalla> createState() => _OrdenesPantallaState();
}

class _OrdenesPantallaState extends State<OrdenesPantalla> {
  late final repo = TallerScope.of(context);
  EstadoOrden? _estado; // filtro por un estado concreto
  bool _todas = false; // true = sin filtro de estado
  String _busqueda = '';
  Stream<List<OrdenResumen>>? _stream;

  /// Se recrea el Stream solo cuando cambian los filtros.
  void _recargar() {
    final estados = _todas
        ? null
        : (_estado == null ? EstadoOrdenX.abiertos : [_estado!]);
    _stream = repo.watchOrdenes(estados: estados, busqueda: _busqueda);
  }

  void _elegir({EstadoOrden? estado, bool todas = false}) {
    setState(() {
      _estado = estado;
      _todas = todas;
      _recargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stream == null) _recargar();
    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes de servicio')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_ordenes', // único dentro del IndexedStack del Shell
        tooltip: 'Nueva orden',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const OrdenNuevaPantalla())),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        CampoBusqueda(
          pista: 'Buscar matrícula, cliente o problema',
          alCambiar: (t) => setState(() {
            _busqueda = t;
            _recargar();
          }),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _chip('Abiertas', !_todas && _estado == null, () => _elegir()),
              for (final e in EstadoOrden.values)
                _chip(e.etiqueta, !_todas && _estado == e, () => _elegir(estado: e),
                    color: colorEstado(e)),
              _chip('Todas', _todas, () => _elegir(todas: true)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<OrdenResumen>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              if (!snap.hasData) return const Cargando();
              final lista = snap.data!;
              if (lista.isEmpty) {
                return const Vacio(
                    icono: Icons.assignment_turned_in_outlined,
                    texto: 'No hay órdenes con este filtro');
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: lista.length,
                itemBuilder: (_, i) => OrdenTile(lista[i]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _chip(String texto, bool sel, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(texto),
        selected: sel,
        onSelected: (_) => onTap(),
        selectedColor: (color ?? Colores.azul).withAlpha(40),
        checkmarkColor: color ?? Colores.azul,
      ),
    );
  }
}
