// =============================================================================
// reportes.dart — Reportes para el dueño (Solución A).
// Un SegmentedButton cambia entre 4 reportes: Facturación de un período,
// Deudores, Carga por mecánico y Repuestos por agotarse.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../comun.dart';
import '../tema.dart';
import '../widgets/orden_tile.dart';
import 'cliente_detalle.dart';

class ReportesPantalla extends StatefulWidget {
  const ReportesPantalla({super.key});
  @override
  State<ReportesPantalla> createState() => _ReportesPantallaState();
}

class _ReportesPantallaState extends State<ReportesPantalla> {
  int _reporte = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, icon: Icon(Icons.attach_money), label: Text('Factura')),
              ButtonSegment(value: 1, icon: Icon(Icons.person_search), label: Text('Deudas')),
              ButtonSegment(value: 2, icon: Icon(Icons.engineering), label: Text('Carga')),
              ButtonSegment(value: 3, icon: Icon(Icons.inventory), label: Text('Stock')),
            ],
            selected: {_reporte},
            onSelectionChanged: (s) => setState(() => _reporte = s.first),
          ),
        ),
        Expanded(
          child: switch (_reporte) {
            0 => const _Facturacion(),
            1 => const _Deudores(),
            2 => const _Carga(),
            _ => const _Stock(),
          },
        ),
      ]),
    );
  }
}

// ----------------------------------------------------------------- Facturación
class _Facturacion extends StatefulWidget {
  const _Facturacion();
  @override
  State<_Facturacion> createState() => _FacturacionState();
}

class _FacturacionState extends State<_Facturacion> {
  late final repo = TallerScope.of(context);
  String _periodo = 'mes';
  late DateTimeRange _rango = _calcular('mes');
  late Stream<ReporteFacturacion> _stream = repo.watchFacturacion(_rango.start, _rango.end);

  DateTimeRange _calcular(String p) {
    final h = DateTime.now();
    final hoy = DateTime(h.year, h.month, h.day);
    return switch (p) {
      'hoy' => DateTimeRange(start: hoy, end: hoy),
      'semana' => DateTimeRange(start: hoy.subtract(Duration(days: hoy.weekday - 1)), end: hoy),
      'mes' => DateTimeRange(start: DateTime(hoy.year, hoy.month, 1), end: hoy),
      _ => DateTimeRange(
          start: DateTime(hoy.year, hoy.month - 1, 1), end: DateTime(hoy.year, hoy.month, 0)),
    };
  }

  void _aplicar(String p, DateTimeRange r) {
    setState(() {
      _periodo = p;
      _rango = r;
      _stream = repo.watchFacturacion(r.start, r.end);
    });
  }

  Future<void> _personalizado() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _rango,
    );
    if (r != null) _aplicar('otro', r);
  }

  @override
  Widget build(BuildContext context) {
    Widget chip(String clave, String texto) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(texto),
            selected: _periodo == clave,
            onSelected: (_) => _aplicar(clave, _calcular(clave)),
          ),
        );
    return Column(children: [
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          children: [
            chip('hoy', 'Hoy'),
            chip('semana', 'Esta semana'),
            chip('mes', 'Este mes'),
            chip('anterior', 'Mes anterior'),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: const Text('Elegir…'),
                selected: _periodo == 'otro',
                onSelected: (_) => _personalizado(),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: StreamBuilder<ReporteFacturacion>(
          stream: _stream,
          builder: (context, snap) {
            if (!snap.hasData) return const Cargando();
            final r = snap.data!;
            return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              Seccion(
                titulo: '${fecha(r.desde)} – ${fecha(r.hasta)}',
                icono: Icons.calendar_month,
                child: Column(children: [
                  FilaValor('Órdenes entregadas', '${r.cantidad}'),
                  FilaValor('Mano de obra', dinero(r.manoObra)),
                  FilaValor('Repuestos', dinero(r.repuestos)),
                  const Divider(),
                  FilaValor('Total facturado', dinero(r.facturado),
                      destacado: true, color: Colores.azul),
                  FilaValor('Dinero cobrado en el período', dinero(r.cobrado),
                      color: Colores.exito),
                ]),
              ),
              if (r.ordenes.isEmpty)
                const Vacio(icono: Icons.receipt_long, texto: 'No hubo entregas en este período'),
              for (final o in r.ordenes) OrdenTile(o),
            ]);
          },
        ),
      ),
    ]);
  }
}

// ----------------------------------------------------------------- Deudores
class _Deudores extends StatefulWidget {
  const _Deudores();
  @override
  State<_Deudores> createState() => _DeudoresState();
}

class _DeudoresState extends State<_Deudores> {
  late final _stream = TallerScope.of(context).watchDeudores();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Deudor>>(
      stream: _stream,
      builder: (context, snap) {
        if (!snap.hasData) return const Cargando();
        final lista = snap.data!;
        final total = lista.fold<double>(0, (s, d) => s + d.saldo);
        return ListView(children: [
          Seccion(
            titulo: 'Total por cobrar',
            icono: Icons.account_balance_wallet_outlined,
            child: FilaValor('${lista.length} cliente(s) con saldo', dinero(total),
                destacado: true, color: Colores.peligro),
          ),
          if (lista.isEmpty) const Vacio(icono: Icons.verified, texto: 'Nadie debe dinero'),
          for (final d in lista)
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFDECEC),
                  child: Icon(Icons.person, color: Colores.peligro)),
              title: Text(d.nombre),
              subtitle: Text('${d.telefono} · ${d.ordenesConSaldo} orden(es)'),
              trailing: Text(dinero(d.saldo),
                  style: const TextStyle(color: Colores.peligro, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ClienteDetallePantalla(clienteId: d.clienteId))),
            ),
        ]);
      },
    );
  }
}

// ----------------------------------------------------------------- Carga
class _Carga extends StatefulWidget {
  const _Carga();
  @override
  State<_Carga> createState() => _CargaState();
}

class _CargaState extends State<_Carga> {
  late final _stream = TallerScope.of(context).watchCargaMecanicos();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CargaMecanico>>(
      stream: _stream,
      builder: (context, snap) {
        if (!snap.hasData) return const Cargando();
        return ListView(children: [
          for (final c in snap.data!)
            Seccion(
              titulo: c.mecanico.nombre + (c.mecanico.activo ? '' : ' (inactivo)'),
              icono: Icons.engineering,
              accion: Text('${c.abiertas}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: Colores.naranja)),
              child: Column(children: [
                FilaValor('Recibidas / en diagnóstico', '${c.enDiagnostico}'),
                FilaValor('En reparación', '${c.enReparacion}'),
                FilaValor('Listas para entregar', '${c.listas}'),
              ]),
            ),
        ]);
      },
    );
  }
}

// ----------------------------------------------------------------- Stock
class _Stock extends StatefulWidget {
  const _Stock();
  @override
  State<_Stock> createState() => _StockState();
}

class _StockState extends State<_Stock> {
  late final _stream = TallerScope.of(context).watchRepuestosBajos();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Repuesto>>(
      stream: _stream,
      builder: (context, snap) {
        if (!snap.hasData) return const Cargando();
        final lista = snap.data!;
        if (lista.isEmpty) {
          return const Vacio(icono: Icons.check_circle_outline, texto: 'Ningún repuesto por agotarse');
        }
        return ListView(children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Lista de compra sugerida',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          for (final r in lista)
            ListTile(
              leading: Icon(Icons.warning_amber,
                  color: r.existencias == 0 ? Colores.peligro : Colores.aviso),
              title: Text(r.nombre),
              subtitle: Text('${r.codigo} · hay ${r.existencias}, mínimo ${r.stockMinimo}'),
              // Sugerencia: comprar hasta el doble del mínimo.
              trailing: Text('Comprar ${(r.stockMinimo * 2 - r.existencias).clamp(1, 9999)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ]);
      },
    );
  }
}
