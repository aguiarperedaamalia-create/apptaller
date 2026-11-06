// =============================================================================
// inicio.dart — Tablero principal (Solución A).
// Responde de un vistazo a las preguntas del dueño: cuántas órdenes hay en
// cada estado, cuánto se debe, qué repuestos se agotan y cómo está repartido
// el trabajo entre los mecánicos. Todo se actualiza solo (StreamBuilder).
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../../data/base_datos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../comun.dart';
import '../tema.dart';
import 'mecanicos.dart';
import 'orden_nueva.dart';

class InicioPantalla extends StatefulWidget {
  /// Callback para cambiar de pestaña en el Shell (1 = Órdenes, 3 = Inventario…).
  final ValueChanged<int> irA;
  const InicioPantalla({super.key, required this.irA});

  @override
  State<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends State<InicioPantalla> {
  // Campos `late`: se crean la primera vez que build los usa (ahí ya se
  // puede leer el InheritedWidget). Así cada Stream se crea UNA sola vez.
  late final repo = TallerScope.of(context);
  late final _conteo = repo.watchConteoPorEstado();
  late final _bajos = repo.watchRepuestosBajos();
  late final _deudores = repo.watchDeudores();
  late final _carga = repo.watchCargaMecanicos();

  Future<void> _menu(String opcion) async {
    if (opcion == 'mecanicos') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MecanicosPantalla()));
    } else if (opcion == 'demo') {
      await ejecutar(context, repo.cargarDatosDemo, exito: 'Datos de ejemplo cargados');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.settings_suggest, color: Colores.naranja),
          SizedBox(width: 8),
          Text('El Pistón'),
        ]),
        actions: [
          PopupMenuButton<String>(
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'mecanicos', child: Text('Mecánicos')),
              PopupMenuItem(value: 'demo', child: Text('Cargar datos de ejemplo')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // heroTag propio: las 5 pestañas viven a la vez en el IndexedStack y
        // dos FAB con el tag por defecto provocan error de Hero al navegar.
        heroTag: 'fab_inicio',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const OrdenNuevaPantalla())),
        icon: const Icon(Icons.add),
        label: const Text('Nueva orden'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          _encabezado(),
          _estados(),
          _alertasStock(),
          _cargaMecanicos(),
        ],
      ),
    );
  }

  /// Banda azul con los dos números clave: órdenes abiertas y dinero por cobrar.
  Widget _encabezado() {
    return Container(
      color: Colores.azul,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Row(children: [
        Expanded(
          child: StreamBuilder<Map<EstadoOrden, int>>(
            stream: _conteo,
            builder: (context, snap) {
              final m = snap.data ?? const <EstadoOrden, int>{};
              final abiertas = EstadoOrdenX.abiertos.fold<int>(0, (s, e) => s + (m[e] ?? 0));
              return _Indicador(
                  titulo: 'Órdenes abiertas', valor: '$abiertas', onTap: () => widget.irA(1));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<Deudor>>(
            stream: _deudores,
            builder: (context, snap) {
              final total = (snap.data ?? const <Deudor>[]).fold<double>(0, (s, d) => s + d.saldo);
              return _Indicador(
                  titulo: 'Por cobrar', valor: dinero(total, conMoneda: false),
                  sufijo: kMoneda, onTap: () => widget.irA(4));
            },
          ),
        ),
      ]),
    );
  }

  Widget _estados() {
    return Seccion(
      titulo: 'Órdenes por estado',
      icono: Icons.timeline,
      child: StreamBuilder<Map<EstadoOrden, int>>(
        stream: _conteo,
        builder: (context, snap) {
          if (!snap.hasData) return const Cargando();
          final m = snap.data!;
          return Column(
            children: [
              for (final e in EstadoOrdenX.abiertos)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: colorEstado(e).withAlpha(35),
                    child: Icon(iconoEstado(e), size: 18, color: colorEstado(e)),
                  ),
                  title: Text(e.etiqueta, style: const TextStyle(fontSize: 15)),
                  trailing: Text('${m[e] ?? 0}',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700, color: colorEstado(e))),
                  onTap: () => widget.irA(1),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _alertasStock() {
    return StreamBuilder<List<Repuesto>>(
      stream: _bajos,
      builder: (context, snap) {
        final lista = snap.data ?? const <Repuesto>[];
        return Seccion(
          titulo: 'Repuestos por agotarse',
          icono: Icons.warning_amber_rounded,
          accion: TextButton(onPressed: () => widget.irA(3), child: const Text('Inventario')),
          child: lista.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(Icons.check_circle, color: Colores.exito),
                    SizedBox(width: 8),
                    Expanded(child: Text('Todo el inventario está por encima del mínimo')),
                  ]),
                )
              : Column(children: [
                  for (final r in lista)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.error_outline, color: Colores.aviso),
                      title: Text(r.nombre),
                      subtitle: Text('${r.codigo} · mínimo ${r.stockMinimo}'),
                      trailing: Text('${r.existencias}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: r.existencias == 0 ? Colores.peligro : Colores.aviso)),
                    ),
                ]),
        );
      },
    );
  }

  Widget _cargaMecanicos() {
    return Seccion(
      titulo: 'Carga de trabajo',
      icono: Icons.engineering,
      child: StreamBuilder<List<CargaMecanico>>(
        stream: _carga,
        builder: (context, snap) {
          if (!snap.hasData) return const Cargando();
          final datos = snap.data!.where((c) => c.mecanico.activo).toList();
          final maximo = datos.fold<int>(1, (m, c) => c.abiertas > m ? c.abiertas : m);
          return Column(children: [
            for (final c in datos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                        child: Text(c.mecanico.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${c.abiertas} abiertas'),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: c.abiertas / maximo,
                      minHeight: 10,
                      color: Colores.naranja,
                      backgroundColor: const Color(0xFFE8ECF1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                      'Diagnóstico ${c.enDiagnostico} · Reparación ${c.enReparacion} · Listas ${c.listas}',
                      style: const TextStyle(fontSize: 12, color: Colores.textoSuave)),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final String? sufijo;
  final VoidCallback onTap;
  const _Indicador({required this.titulo, required this.valor, this.sufijo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colores.azulOscuro,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(valor,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
                if (sufijo != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 5),
                    child: Text(sufijo!,
                        style: const TextStyle(color: Colores.naranja, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
