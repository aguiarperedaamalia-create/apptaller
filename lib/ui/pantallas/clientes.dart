// =============================================================================
// clientes.dart — Lista de clientes (Solución A).
// Búsqueda por nombre, teléfono o matrícula de alguno de sus vehículos.
// Cada fila muestra cuántos vehículos tiene y, en rojo, si debe dinero.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../comun.dart';
import '../tema.dart';
import 'cliente_detalle.dart';
import 'formularios.dart';

class ClientesPantalla extends StatefulWidget {
  const ClientesPantalla({super.key});
  @override
  State<ClientesPantalla> createState() => _ClientesPantallaState();
}

class _ClientesPantallaState extends State<ClientesPantalla> {
  late final repo = TallerScope.of(context);
  late Stream<List<ClienteResumen>> _stream = repo.watchClientes();

  Future<void> _nuevo() async {
    final id = await Navigator.push<int>(
        context, MaterialPageRoute(builder: (_) => const ClienteFormPantalla()));
    if (id == null || !mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ClienteDetallePantalla(clienteId: id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_clientes', // único dentro del IndexedStack del Shell
        tooltip: 'Nuevo cliente',
        onPressed: _nuevo,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Column(children: [
        CampoBusqueda(
          pista: 'Nombre, teléfono o matrícula',
          alCambiar: (t) => setState(() => _stream = repo.watchClientes(busqueda: t)),
        ),
        Expanded(
          child: StreamBuilder<List<ClienteResumen>>(
            stream: _stream,
            builder: (context, snap) {
              if (!snap.hasData) return const Cargando();
              final lista = snap.data!;
              if (lista.isEmpty) {
                return const Vacio(icono: Icons.people_outline, texto: 'No hay clientes');
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final c = lista[i];
                  final debe = c.saldoPendiente > 0.009;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colores.azul.withAlpha(25),
                      child: Text(c.cliente.nombre.characters.first.toUpperCase(),
                          style: const TextStyle(
                              color: Colores.azul, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(c.cliente.nombre, style: const TextStyle(fontSize: 16)),
                    subtitle: Text(
                        '${c.cliente.telefono} · ${c.vehiculos} vehículo${c.vehiculos == 1 ? '' : 's'}'),
                    trailing: debe
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Debe',
                                  style: TextStyle(fontSize: 11, color: Colores.peligro)),
                              Text(dinero(c.saldoPendiente),
                                  style: const TextStyle(
                                      color: Colores.peligro, fontWeight: FontWeight.w700)),
                            ],
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ClienteDetallePantalla(clienteId: c.cliente.id))),
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
