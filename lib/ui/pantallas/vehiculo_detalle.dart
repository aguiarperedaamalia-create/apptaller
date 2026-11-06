// =============================================================================
// vehiculo_detalle.dart — Ficha del vehículo con su historial de servicios
// (Solución A). Desde aquí se abre una orden nueva para este vehículo.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../comun.dart';
import '../tema.dart';
import '../widgets/orden_tile.dart';
import 'formularios.dart';
import 'orden_nueva.dart';

class VehiculoDetallePantalla extends StatefulWidget {
  final int vehiculoId;
  const VehiculoDetallePantalla({super.key, required this.vehiculoId});
  @override
  State<VehiculoDetallePantalla> createState() => _VehiculoDetallePantallaState();
}

class _VehiculoDetallePantallaState extends State<VehiculoDetallePantalla> {
  late final repo = TallerScope.of(context);
  late final _vehiculo = repo.watchVehiculo(widget.vehiculoId);
  late final _historial = repo.watchOrdenes(vehiculoId: widget.vehiculoId);

  Future<void> _eliminar() async {
    final ok = await confirmar(context,
        titulo: 'Eliminar vehículo',
        mensaje: 'Solo se permite si nunca ha tenido órdenes.',
        accion: 'Eliminar');
    if (!ok || !mounted) return;
    final hecho = await ejecutar(context, () => repo.eliminarVehiculo(widget.vehiculoId));
    if (hecho && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Vehiculo?>(
      stream: _vehiculo,
      builder: (context, snap) {
        if (!snap.hasData) return Scaffold(appBar: AppBar(), body: const Cargando());
        final v = snap.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(v.matricula),
            actions: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => VehiculoFormPantalla(clienteId: v.clienteId, vehiculo: v))),
              ),
              IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete_outline), onPressed: _eliminar),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => OrdenNuevaPantalla(vehiculoId: v.id))),
            icon: const Icon(Icons.add_task),
            label: const Text('Nueva orden'),
          ),
          body: StreamBuilder<List<OrdenResumen>>(
            stream: _historial,
            builder: (context, snapH) {
              final hist = snapH.data ?? const <OrdenResumen>[];
              final gastado = hist
                  .where((o) => o.estado != EstadoOrden.cancelada)
                  .fold<double>(0, (s, o) => s + o.total);
              return ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 90),
                children: [
                  Seccion(
                    titulo: '${v.marca} ${v.modelo} (${v.anio})',
                    icono: Icons.directions_car,
                    child: Column(children: [
                      FilaValor('Último kilometraje', '${numero(v.kilometraje)} km'),
                      FilaValor('Visitas al taller', '${hist.length}'),
                      FilaValor('Total invertido', dinero(gastado)),
                      if (hist.isNotEmpty)
                        FilaValor('Última visita', fecha(hist.first.fechaEntrada)),
                    ]),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('Historial de servicios',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colores.texto)),
                  ),
                  if (hist.isEmpty)
                    const Vacio(icono: Icons.history, texto: 'Este vehículo no tiene órdenes'),
                  for (final o in hist) OrdenTile(o),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
