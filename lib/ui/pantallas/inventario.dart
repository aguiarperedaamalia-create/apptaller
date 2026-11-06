// =============================================================================
// inventario.dart — Inventario de repuestos (Solución A).
// Búsqueda, filtro "solo por agotarse", alta/edición y reabastecimiento.
// El número de existencias cambia de color: verde (ok), naranja (bajo el
// mínimo) y rojo (agotado), siempre acompañado de texto.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../comun.dart';
import '../dialogos.dart';
import '../tema.dart';
import 'formularios.dart';

class InventarioPantalla extends StatefulWidget {
  const InventarioPantalla({super.key});
  @override
  State<InventarioPantalla> createState() => _InventarioPantallaState();
}

class _InventarioPantallaState extends State<InventarioPantalla> {
  late final repo = TallerScope.of(context);
  String _busqueda = '';
  bool _soloBajos = false;
  late Stream<List<Repuesto>> _stream = repo.watchRepuestos();

  void _recargar() =>
      _stream = repo.watchRepuestos(busqueda: _busqueda, soloBajos: _soloBajos);

  Future<void> _reabastecer(Repuesto r) async {
    final cant = await showDialog<int>(
      context: context,
      builder: (_) => DialogoCantidad(titulo: 'Entrada de "${r.nombre}"', maximo: 500),
    );
    if (cant == null || !mounted) return;
    await ejecutar(context, () => repo.reabastecer(r.id, cant),
        exito: '+$cant unidades de ${r.nombre}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_inventario', // único dentro del IndexedStack del Shell
        tooltip: 'Nuevo repuesto',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const RepuestoFormPantalla())),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        CampoBusqueda(
          pista: 'Buscar por nombre o código',
          alCambiar: (t) => setState(() {
            _busqueda = t;
            _recargar();
          }),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Mostrar solo los que están por agotarse'),
          value: _soloBajos,
          onChanged: (v) => setState(() {
            _soloBajos = v;
            _recargar();
          }),
        ),
        Expanded(
          child: StreamBuilder<List<Repuesto>>(
            stream: _stream,
            builder: (context, snap) {
              if (!snap.hasData) return const Cargando();
              final lista = snap.data!;
              if (lista.isEmpty) {
                return const Vacio(icono: Icons.inventory_2_outlined, texto: 'Sin repuestos');
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: lista.length,
                itemBuilder: (_, i) => _fila(lista[i]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _fila(Repuesto r) {
    final agotado = r.existencias == 0;
    final bajo = r.existencias <= r.stockMinimo;
    final color = agotado ? Colores.peligro : (bajo ? Colores.aviso : Colores.exito);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: bajo ? color.withAlpha(120) : const Color(0xFFE1E6EC)),
      ),
      child: ListTile(
        title: Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${r.codigo} · ${dinero(r.precioVenta)} · mín. ${r.stockMinimo}'),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => RepuestoFormPantalla(repuesto: r))),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${r.existencias}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            Text(agotado ? 'agotado' : (bajo ? 'bajo' : 'ok'),
                style: TextStyle(fontSize: 11, color: color)),
          ]),
          IconButton(
            tooltip: 'Reabastecer',
            icon: const Icon(Icons.add_shopping_cart, color: Colores.azul),
            onPressed: () => _reabastecer(r),
          ),
        ]),
      ),
    );
  }
}
