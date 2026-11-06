// =============================================================================
// cliente_detalle.dart — Ficha del cliente (Solución A).
// Muestra datos de contacto, saldo pendiente, sus vehículos y el HISTORIAL de
// todas sus órdenes. Desde aquí se editan/eliminan cliente y vehículos.
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
import 'vehiculo_detalle.dart';

class ClienteDetallePantalla extends StatefulWidget {
  final int clienteId;
  const ClienteDetallePantalla({super.key, required this.clienteId});
  @override
  State<ClienteDetallePantalla> createState() => _ClienteDetallePantallaState();
}

class _ClienteDetallePantallaState extends State<ClienteDetallePantalla> {
  late final repo = TallerScope.of(context);
  late final _cliente = repo.watchCliente(widget.clienteId);
  late final _vehiculos = repo.watchVehiculosDeCliente(widget.clienteId);
  late final _historial = repo.watchOrdenes(clienteId: widget.clienteId);

  Future<void> _eliminar() async {
    final ok = await confirmar(context,
        titulo: 'Eliminar cliente', mensaje: 'Solo se permite si no tiene vehículos.',
        accion: 'Eliminar');
    if (!ok || !mounted) return;
    final hecho = await ejecutar(context, () => repo.eliminarCliente(widget.clienteId));
    if (hecho && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Cliente?>(
      stream: _cliente,
      builder: (context, snap) {
        if (!snap.hasData) return Scaffold(appBar: AppBar(), body: const Cargando());
        final c = snap.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(c.nombre),
            actions: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ClienteFormPantalla(cliente: c))),
              ),
              IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete_outline), onPressed: _eliminar),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => VehiculoFormPantalla(clienteId: c.id))),
            icon: const Icon(Icons.add),
            label: const Text('Vehículo'),
          ),
          body: StreamBuilder<List<OrdenResumen>>(
            stream: _historial,
            builder: (context, snapH) {
              final historial = snapH.data ?? const <OrdenResumen>[];
              // Deuda: órdenes terminadas (lista/entregada) con saldo.
              final deuda = historial
                  .where((o) =>
                      o.estado == EstadoOrden.lista || o.estado == EstadoOrden.entregada)
                  .fold<double>(0, (s, o) => s + (o.saldo > 0 ? o.saldo : 0));
              return ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 90),
                children: [
                  Seccion(
                    titulo: 'Contacto',
                    icono: Icons.contact_phone_outlined,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Teléfono: ${c.telefono}', style: const TextStyle(fontSize: 15)),
                      if (c.direccion != null)
                        Text('Dirección: ${c.direccion}', style: const TextStyle(fontSize: 15)),
                      Text('Cliente desde ${fecha(c.creadoEn)}',
                          style: const TextStyle(color: Colores.textoSuave)),
                      const Divider(),
                      FilaValor('Saldo pendiente', dinero(deuda),
                          destacado: true,
                          color: deuda > 0.009 ? Colores.peligro : Colores.exito),
                    ]),
                  ),
                  Seccion(
                    titulo: 'Vehículos',
                    icono: Icons.directions_car_outlined,
                    child: StreamBuilder<List<Vehiculo>>(
                      stream: _vehiculos,
                      builder: (context, snapV) {
                        final vs = snapV.data ?? const <Vehiculo>[];
                        if (vs.isEmpty) {
                          return const Text('Sin vehículos. Use el botón "+ Vehículo".',
                              style: TextStyle(color: Colores.textoSuave));
                        }
                        return Column(children: [
                          for (final v in vs)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.directions_car, color: Colores.azul),
                              title: Text('${v.matricula} · ${v.marca} ${v.modelo}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${v.anio} · ${numero(v.kilometraje)} km'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => VehiculoDetallePantalla(vehiculoId: v.id))),
                            ),
                        ]);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('Historial de servicios',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  if (historial.isEmpty)
                    const Vacio(icono: Icons.history, texto: 'Todavía no hay órdenes'),
                  for (final o in historial) OrdenTile(o),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
