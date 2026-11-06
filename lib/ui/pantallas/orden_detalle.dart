// =============================================================================
// orden_detalle.dart — Detalle y gestión completa de una orden (Solución A).
// Una sola página desplazable con tarjetas: datos, progreso de estados,
// trabajos, repuestos, pagos y totales. Cada sección escucha su propio Stream,
// así al agregar un repuesto se actualizan la lista, los totales y el saldo.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../comun.dart';
import '../dialogos.dart';
import '../tema.dart';
import 'cliente_detalle.dart';
import 'seleccion_repuesto.dart';

class OrdenDetallePantalla extends StatefulWidget {
  final int ordenId;
  const OrdenDetallePantalla({super.key, required this.ordenId});

  @override
  State<OrdenDetallePantalla> createState() => _OrdenDetallePantallaState();
}

class _OrdenDetallePantallaState extends State<OrdenDetallePantalla> {
  late final repo = TallerScope.of(context);
  late final _orden = repo.watchOrden(widget.ordenId);
  late final _trabajos = repo.watchTrabajos(widget.ordenId);
  late final _repuestos = repo.watchRepuestosDeOrden(widget.ordenId);
  late final _pagos = repo.watchPagos(widget.ordenId);

  // ---------------------------------------------------------------- acciones
  Future<void> _avanzar(OrdenResumen o) async {
    final sig = o.estado.siguiente!;
    if (sig == EstadoOrden.entregada && o.saldo > 0.009) {
      final ok = await confirmar(context,
          titulo: 'Entregar con saldo pendiente',
          mensaje: 'El cliente aún debe ${dinero(o.saldo)}. ¿Entregar el vehículo de todos modos?',
          accion: 'Entregar');
      if (!ok || !mounted) return;
    }
    await ejecutar(context, () => repo.avanzarEstado(o.id),
        exito: 'Orden #${o.id}: ${sig.etiqueta}');
  }

  Future<void> _menu(String op, OrdenResumen o) async {
    switch (op) {
      case 'mecanico':
        final mecs = await repo.watchMecanicos(soloActivos: true).first;
        if (!mounted) return;
        final id = await elegirMecanico(context, mecs, o.mecanicoId);
        if (id == null || !mounted) return;
        await ejecutar(context, () => repo.actualizarOrden(o.id, mecanicoId: id),
            exito: 'Mecánico reasignado');
      case 'problema':
        final t = await showDialog<String>(
            context: context,
            builder: (_) => DialogoTexto(titulo: 'Problema reportado', inicial: o.problema));
        if (t == null || t.isEmpty || !mounted) return;
        await ejecutar(context, () => repo.actualizarOrden(o.id, problema: t));
      case 'retroceder':
        await ejecutar(context, () => repo.retrocederEstado(o.id));
      case 'cancelar':
        final ok = await confirmar(context,
            titulo: 'Cancelar orden #${o.id}',
            mensaje: 'Los repuestos usados volverán al inventario. Esta acción no se puede deshacer.',
            accion: 'Cancelar orden');
        if (!ok || !mounted) return;
        await ejecutar(context, () => repo.cancelarOrden(o.id), exito: 'Orden cancelada');
    }
  }

  Future<void> _agregarTrabajo() async {
    final d = await showDialog<DatosTrabajo>(context: context, builder: (_) => const DialogoTrabajo());
    if (d == null || !mounted) return;
    await ejecutar(context, () => repo.agregarTrabajo(widget.ordenId, d.descripcion, d.precio));
  }

  Future<void> _agregarRepuesto() async {
    final sel = await Navigator.push<SeleccionRepuesto>(
        context, MaterialPageRoute(builder: (_) => const SeleccionRepuestoPantalla()));
    if (sel == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await repo.usarRepuesto(widget.ordenId, sel.repuesto.id, sel.cantidad);
      if (r.quedoBajo) {
        // Aviso inmediato al dueño: el repuesto llegó al mínimo.
        messenger.showSnackBar(SnackBar(
          backgroundColor: Colores.aviso,
          duration: const Duration(seconds: 5),
          content: Text('Quedan ${r.repuesto.existencias} de "${r.repuesto.nombre}": hay que comprar.'),
        ));
      }
    } on ReglaNegocioException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colores.peligro));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colores.peligro));
    }
  }

  Future<void> _registrarPago(OrdenResumen o) async {
    final d = await showDialog<DatosPago>(
        context: context, builder: (_) => DialogoPago(saldo: o.saldo));
    if (d == null || !mounted) return;
    await ejecutar(context, () => repo.registrarPago(o.id, d.monto, metodo: d.metodo),
        exito: 'Pago registrado');
  }

  // ---------------------------------------------------------------- interfaz
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrdenResumen?>(
      stream: _orden,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(appBar: AppBar(), body: const Cargando());
        }
        final o = snap.data!;
        final editable = o.estado.editable;
        return Scaffold(
          appBar: AppBar(
            title: Text('Orden #${o.id}'),
            actions: [
              if (editable)
                PopupMenuButton<String>(
                  onSelected: (op) => _menu(op, o),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'mecanico', child: Text('Cambiar mecánico')),
                    const PopupMenuItem(value: 'problema', child: Text('Editar problema')),
                    if (o.estado.anterior != null)
                      PopupMenuItem(
                          value: 'retroceder',
                          child: Text('Volver a "${o.estado.anterior!.etiqueta}"')),
                    const PopupMenuItem(
                        value: 'cancelar',
                        child: Text('Cancelar orden', style: TextStyle(color: Colores.peligro))),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(top: 6, bottom: 100),
            children: [
              _datos(o),
              _progreso(o),
              _seccionTrabajos(editable),
              _seccionRepuestos(o, editable),
              _seccionPagos(o),
              _totales(o),
            ],
          ),
          // Botón principal: la siguiente acción del flujo, siempre visible.
          bottomNavigationBar: o.estado.siguiente == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: colorEstado(o.estado.siguiente!),
                          minimumSize: const Size.fromHeight(54)),
                      onPressed: () => _avanzar(o),
                      icon: Icon(iconoEstado(o.estado.siguiente!)),
                      label: Text('Pasar a: ${o.estado.siguiente!.etiqueta}'),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _datos(OrdenResumen o) {
    return Seccion(
      titulo: '${o.matricula} · ${o.vehiculoTexto}',
      icono: Icons.directions_car,
      accion: EstadoChip(o.estado, compacto: true),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text(o.clienteNombre, style: const TextStyle(fontSize: 15)),
          subtitle: Text(o.clienteTelefono),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ClienteDetallePantalla(clienteId: o.clienteId))),
        ),
        _linea(Icons.engineering_outlined, 'Mecánico', o.mecanicoNombre),
        _linea(Icons.login, 'Entrada', fechaHora(o.fechaEntrada)),
        if (o.fechaEntrega != null) _linea(Icons.logout, 'Entrega', fechaHora(o.fechaEntrega!)),
        _linea(Icons.speed, 'Kilometraje', '${numero(o.kilometrajeEntrada)} km'),
        const Divider(),
        const Text('Problema reportado', style: TextStyle(color: Colores.textoSuave)),
        Text(o.problema, style: const TextStyle(fontSize: 15)),
      ]),
    );
  }

  Widget _linea(IconData i, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(i, size: 18, color: Colores.textoSuave),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(k, style: const TextStyle(color: Colores.textoSuave))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
      );

  /// Barra de progreso del flujo de estados (5 pasos).
  Widget _progreso(OrdenResumen o) {
    if (o.estado == EstadoOrden.cancelada) {
      return const Seccion(
        titulo: 'Orden cancelada',
        icono: Icons.cancel,
        child: Text('Los repuestos se devolvieron al inventario.'),
      );
    }
    final actual = EstadoOrdenX.flujo.indexOf(o.estado);
    return Seccion(
      titulo: 'Progreso',
      icono: Icons.timeline,
      child: Column(children: [
        Row(children: [
          for (var i = 0; i < EstadoOrdenX.flujo.length; i++) ...[
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: i <= actual ? colorEstado(o.estado) : const Color(0xFFE1E6EC),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            if (i < EstadoOrdenX.flujo.length - 1) const SizedBox(width: 4),
          ],
        ]),
        const SizedBox(height: 6),
        Row(children: [
          for (final e in EstadoOrdenX.flujo)
            Expanded(
              child: Text(
                e.etiqueta.replaceFirst('Lista para entregar', 'Lista').replaceFirst('En ', ''),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: e == o.estado ? FontWeight.w700 : FontWeight.w400,
                  color: e == o.estado ? Colores.texto : Colores.textoSuave,
                ),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _seccionTrabajos(bool editable) {
    return StreamBuilder<List<Trabajo>>(
      stream: _trabajos,
      builder: (context, snap) {
        final lista = snap.data ?? const <Trabajo>[];
        return Seccion(
          titulo: 'Trabajos realizados',
          icono: Icons.handyman_outlined,
          accion: editable
              ? IconButton(
                  tooltip: 'Agregar trabajo',
                  onPressed: _agregarTrabajo,
                  icon: const Icon(Icons.add_circle, color: Colores.naranja))
              : null,
          child: lista.isEmpty
              ? const Text('Sin trabajos registrados', style: TextStyle(color: Colores.textoSuave))
              : Column(children: [
                  for (final t in lista)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.descripcion, style: const TextStyle(fontSize: 15)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(dinero(t.precio)),
                        if (editable)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              final ok = await confirmar(context,
                                  titulo: 'Eliminar trabajo',
                                  mensaje: '¿Eliminar "${t.descripcion}"?',
                                  accion: 'Eliminar');
                              if (!ok || !context.mounted) return;
                              await ejecutar(context, () => repo.eliminarTrabajo(t));
                            },
                          ),
                      ]),
                    ),
                ]),
        );
      },
    );
  }

  Widget _seccionRepuestos(OrdenResumen o, bool editable) {
    return StreamBuilder<List<RepuestoUsadoDetalle>>(
      stream: _repuestos,
      builder: (context, snap) {
        final lista = snap.data ?? const <RepuestoUsadoDetalle>[];
        return Seccion(
          titulo: 'Repuestos usados',
          icono: Icons.settings_outlined,
          accion: editable
              ? IconButton(
                  tooltip: 'Agregar repuesto',
                  onPressed: _agregarRepuesto,
                  icon: const Icon(Icons.add_circle, color: Colores.naranja))
              : null,
          child: lista.isEmpty
              ? const Text('Sin repuestos', style: TextStyle(color: Colores.textoSuave))
              : Column(children: [
                  for (final r in lista)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.nombre, style: const TextStyle(fontSize: 15)),
                      subtitle: Text('${r.codigo} · ${r.cantidad} × ${dinero(r.precioUnitario)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(dinero(r.subtotal)),
                        if (editable)
                          IconButton(
                            tooltip: 'Quitar y devolver al inventario',
                            icon: const Icon(Icons.undo, size: 20),
                            onPressed: () async {
                              final ok = await confirmar(context,
                                  titulo: 'Quitar repuesto',
                                  mensaje: 'Se devolverán ${r.cantidad} unidad(es) al inventario.',
                                  accion: 'Quitar');
                              if (!ok || !context.mounted) return;
                              await ejecutar(context, () => repo.devolverRepuesto(r, o.id));
                            },
                          ),
                      ]),
                    ),
                ]),
        );
      },
    );
  }

  Widget _seccionPagos(OrdenResumen o) {
    final puedeCobrar = o.estado != EstadoOrden.cancelada && o.saldo > 0.009;
    return StreamBuilder<List<Pago>>(
      stream: _pagos,
      builder: (context, snap) {
        final lista = snap.data ?? const <Pago>[];
        return Seccion(
          titulo: 'Pagos',
          icono: Icons.payments_outlined,
          accion: puedeCobrar
              ? TextButton.icon(
                  onPressed: () => _registrarPago(o),
                  icon: const Icon(Icons.add),
                  label: const Text('Cobrar'))
              : null,
          child: lista.isEmpty
              ? const Text('Sin pagos registrados', style: TextStyle(color: Colores.textoSuave))
              : Column(children: [
                  for (final p in lista)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                          p.metodo == 'Efectivo' ? Icons.payments_outlined : Icons.phone_android),
                      title: Text(dinero(p.monto), style: const TextStyle(fontSize: 15)),
                      subtitle: Text('${p.metodo} · ${fechaHora(p.fecha)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          final ok = await confirmar(context,
                              titulo: 'Eliminar pago',
                              mensaje: '¿Eliminar el pago de ${dinero(p.monto)}?',
                              accion: 'Eliminar');
                          if (!ok || !context.mounted) return;
                          await ejecutar(context, () => repo.eliminarPago(p));
                        },
                      ),
                    ),
                ]),
        );
      },
    );
  }

  Widget _totales(OrdenResumen o) {
    return Seccion(
      titulo: 'Totales',
      icono: Icons.receipt_long_outlined,
      child: Column(children: [
        FilaValor('Mano de obra', dinero(o.manoObra)),
        FilaValor('Repuestos', dinero(o.totalRepuestos)),
        const Divider(),
        FilaValor('Total', dinero(o.total), destacado: true),
        FilaValor('Pagado', dinero(o.pagado), color: Colores.exito),
        FilaValor('Saldo pendiente', dinero(o.saldo),
            destacado: true, color: o.saldo > 0.009 ? Colores.peligro : Colores.exito),
      ]),
    );
  }
}
