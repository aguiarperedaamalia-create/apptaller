// =============================================================================
// mecanicos.dart — Gestión de mecánicos (Solución A).
// Añadir, renombrar y activar/desactivar. Un mecánico inactivo no aparece al
// asignar órdenes nuevas, pero se conserva en el historial.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/taller_scope.dart';
import '../comun.dart';
import '../dialogos.dart';

class MecanicosPantalla extends StatefulWidget {
  const MecanicosPantalla({super.key});
  @override
  State<MecanicosPantalla> createState() => _MecanicosPantallaState();
}

class _MecanicosPantallaState extends State<MecanicosPantalla> {
  late final repo = TallerScope.of(context);
  late final _stream = repo.watchMecanicos();

  Future<void> _editar([Mecanico? m]) async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => DialogoTexto(
          titulo: m == null ? 'Nuevo mecánico' : 'Renombrar', inicial: m?.nombre ?? ''),
    );
    if (nombre == null || nombre.isEmpty || !mounted) return;
    await ejecutar(context,
        () => repo.guardarMecanico(id: m?.id, nombre: nombre, activo: m?.activo ?? true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mecánicos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editar(),
        child: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<List<Mecanico>>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData) return const Cargando();
          return ListView(children: [
            for (final m in snap.data!)
              ListTile(
                leading: const Icon(Icons.engineering),
                title: Text(m.nombre),
                subtitle: Text(m.activo ? 'Activo' : 'Inactivo'),
                onTap: () => _editar(m),
                trailing: Switch(
                  value: m.activo,
                  onChanged: (v) => ejecutar(
                      context, () => repo.guardarMecanico(id: m.id, nombre: m.nombre, activo: v)),
                ),
              ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Toque un nombre para renombrarlo; use el interruptor para activarlo.'),
            ),
          ]);
        },
      ),
    );
  }
}
