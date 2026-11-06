// =============================================================================
// seleccion_repuesto.dart — Página para elegir un repuesto del inventario y la
// cantidad a usar en una orden. Devuelve el resultado al cerrar con
// Navigator.pop(context, SeleccionRepuesto(...)).
// Los repuestos sin existencias aparecen deshabilitados.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../comun.dart';
import '../dialogos.dart';
import '../tema.dart';

class SeleccionRepuesto {
  final Repuesto repuesto;
  final int cantidad;
  const SeleccionRepuesto(this.repuesto, this.cantidad);
}

class SeleccionRepuestoPantalla extends StatefulWidget {
  const SeleccionRepuestoPantalla({super.key});

  @override
  State<SeleccionRepuestoPantalla> createState() => _SeleccionRepuestoPantallaState();
}

class _SeleccionRepuestoPantallaState extends State<SeleccionRepuestoPantalla> {
  late final repo = TallerScope.of(context);
  late Stream<List<Repuesto>> _stream = repo.watchRepuestos();

  Future<void> _elegir(Repuesto r) async {
    final cant = await showDialog<int>(
      context: context,
      builder: (_) => DialogoCantidad(titulo: r.nombre, maximo: r.existencias),
    );
    if (cant == null || !mounted) return;
    Navigator.pop(context, SeleccionRepuesto(r, cant));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir repuesto')),
      body: Column(children: [
        CampoBusqueda(
          pista: 'Buscar por nombre o código',
          alCambiar: (t) => setState(() => _stream = repo.watchRepuestos(busqueda: t)),
        ),
        Expanded(
          child: StreamBuilder<List<Repuesto>>(
            stream: _stream,
            builder: (context, snap) {
              if (!snap.hasData) return const Cargando();
              final lista = snap.data!;
              if (lista.isEmpty) {
                return const Vacio(icono: Icons.search_off, texto: 'No se encontraron repuestos');
              }
              return ListView.separated(
                itemCount: lista.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = lista[i];
                  final agotado = r.existencias == 0;
                  final bajo = r.existencias <= r.stockMinimo;
                  return ListTile(
                    enabled: !agotado,
                    title: Text(r.nombre),
                    subtitle: Text('${r.codigo} · ${dinero(r.precioVenta)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${r.existencias}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: agotado
                                    ? Colores.peligro
                                    : (bajo ? Colores.aviso : Colores.exito))),
                        Text(agotado ? 'agotado' : 'en stock', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    onTap: agotado ? null : () => _elegir(r),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
