// =============================================================================
// orden_nueva.dart — Registrar la llegada de un vehículo (Solución A).
// Formulario en UNA página con tres bloques: 1) vehículo (buscar uno
// registrado o dar de alta cliente + vehículo sin salir), 2) mecánico (chips
// que muestran cuántas órdenes abiertas tiene cada uno), 3) problema y km.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../comun.dart';
import '../tema.dart';
import 'formularios.dart';
import 'orden_detalle.dart';

class OrdenNuevaPantalla extends StatefulWidget {
  /// Si se abre desde la ficha de un vehículo, llega preseleccionado.
  final int? vehiculoId;
  const OrdenNuevaPantalla({super.key, this.vehiculoId});

  @override
  State<OrdenNuevaPantalla> createState() => _OrdenNuevaPantallaState();
}

class _OrdenNuevaPantallaState extends State<OrdenNuevaPantalla> {
  late final repo = TallerScope.of(context);
  late final _carga = repo.watchCargaMecanicos();
  final _form = GlobalKey<FormState>();
  final _problema = TextEditingController();
  final _km = TextEditingController();
  Vehiculo? _vehiculo;
  String _duenio = '';
  int? _mecanicoId;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precarga del vehículo indicado (solo la primera vez).
    if (widget.vehiculoId != null && _vehiculo == null && !_cargado) {
      _cargado = true;
      _cargarVehiculo(widget.vehiculoId!);
    }
  }

  bool _cargado = false;

  Future<void> _cargarVehiculo(int id) async {
    final v = await repo.watchVehiculo(id).first;
    if (v == null) return;
    final c = await repo.watchCliente(v.clienteId).first;
    if (!mounted) return;
    setState(() {
      _vehiculo = v;
      _duenio = c?.nombre ?? '';
      _km.text = '${v.kilometraje}';
    });
  }

  @override
  void dispose() {
    _problema.dispose();
    _km.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final id = await Navigator.push<int>(
        context, MaterialPageRoute(builder: (_) => const BuscarVehiculoPantalla()));
    if (id != null) await _cargarVehiculo(id);
  }

  /// Alta rápida: primero el cliente, luego su vehículo.
  Future<void> _clienteNuevo() async {
    final clienteId = await Navigator.push<int>(
        context, MaterialPageRoute(builder: (_) => const ClienteFormPantalla()));
    if (clienteId == null || !mounted) return;
    final vehiculoId = await Navigator.push<int>(context,
        MaterialPageRoute(builder: (_) => VehiculoFormPantalla(clienteId: clienteId)));
    if (vehiculoId != null) await _cargarVehiculo(vehiculoId);
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _fecha = DateTime(d.year, d.month, d.day, _fecha.hour, _fecha.minute));
    }
  }

  Future<void> _guardar() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_vehiculo == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Seleccione el vehículo')));
      return;
    }
    if (_mecanicoId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Asigne un mecánico')));
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final id = await repo.crearOrden(
        vehiculoId: _vehiculo!.id,
        mecanicoId: _mecanicoId!,
        problema: _problema.text,
        kilometraje: leerEntero(_km.text)!,
        fechaEntrada: _fecha,
      );
      if (!mounted) return;
      // Reemplaza esta página por el detalle (al volver no regresa al formulario).
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => OrdenDetallePantalla(ordenId: id)));
    } on ReglaNegocioException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colores.peligro));
    } catch (e) {
      // P. ej. InvalidDataException de Drift si el problema supera 500 caracteres.
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colores.peligro));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva orden de servicio')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.only(top: 6, bottom: 24),
          children: [
            _bloqueVehiculo(),
            _bloqueMecanico(),
            Seccion(
              titulo: '3. Problema y kilometraje',
              icono: Icons.report_problem_outlined,
              child: Column(children: [
                const SizedBox(height: 4),
                TextFormField(
                  controller: _problema,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Problema que reporta el cliente', alignLabelWithHint: true),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Describa el problema' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _km,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Kilometraje al llegar',
                    suffixText: 'km',
                    helperText: _vehiculo == null
                        ? null
                        : 'Último registrado: ${numero(_vehiculo!.kilometraje)} km',
                  ),
                  validator: (v) {
                    final n = leerEntero(v ?? '');
                    return (n == null || n < 0) ? 'Kilometraje inválido' : null;
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text('Fecha de entrada: ${fecha(_fecha)}'),
                  trailing: TextButton(onPressed: _elegirFecha, child: const Text('Cambiar')),
                ),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: Colores.naranja, minimumSize: const Size.fromHeight(54)),
            onPressed: _guardando ? null : _guardar,
            icon: const Icon(Icons.check),
            label: const Text('Registrar orden'),
          ),
        ),
      ),
    );
  }

  Widget _bloqueVehiculo() {
    final v = _vehiculo;
    return Seccion(
      titulo: '1. Vehículo',
      icono: Icons.directions_car_outlined,
      child: v == null
          ? Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                    onPressed: _buscar, icon: const Icon(Icons.search), label: const Text('Buscar')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                    onPressed: _clienteNuevo,
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Cliente nuevo')),
              ),
            ])
          : ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                  backgroundColor: Colores.azul,
                  child: Icon(Icons.directions_car, color: Colors.white)),
              title: Text('${v.matricula} · ${v.marca} ${v.modelo}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('$_duenio · ${v.anio}'),
              trailing: TextButton(onPressed: _buscar, child: const Text('Cambiar')),
            ),
    );
  }

  Widget _bloqueMecanico() {
    return Seccion(
      titulo: '2. Mecánico asignado',
      icono: Icons.engineering_outlined,
      child: StreamBuilder<List<CargaMecanico>>(
        stream: _carga,
        builder: (context, snap) {
          if (!snap.hasData) return const Cargando();
          final activos = snap.data!.where((c) => c.mecanico.activo).toList();
          // Sugerencia: si no se ha elegido, se preselecciona el menos cargado.
          if (_mecanicoId == null && activos.isNotEmpty) {
            final menos = activos.reduce((a, b) => a.abiertas <= b.abiertas ? a : b);
            _mecanicoId = menos.mecanico.id;
          }
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in activos)
              ChoiceChip(
                label: Text('${c.mecanico.nombre} · ${c.abiertas} abiertas'),
                selected: _mecanicoId == c.mecanico.id,
                onSelected: (_) => setState(() => _mecanicoId = c.mecanico.id),
              ),
          ]);
        },
      ),
    );
  }
}

// =============================================================================
// Buscar un vehículo registrado (por matrícula, marca, modelo o dueño).
// Devuelve el id del vehículo elegido.
// =============================================================================
class BuscarVehiculoPantalla extends StatefulWidget {
  const BuscarVehiculoPantalla({super.key});
  @override
  State<BuscarVehiculoPantalla> createState() => _BuscarVehiculoPantallaState();
}

class _BuscarVehiculoPantallaState extends State<BuscarVehiculoPantalla> {
  late final repo = TallerScope.of(context);
  late Stream<List<VehiculoConCliente>> _stream = repo.watchVehiculos();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar vehículo')),
      body: Column(children: [
        CampoBusqueda(
          pista: 'Matrícula, marca, modelo o dueño',
          alCambiar: (t) => setState(() => _stream = repo.watchVehiculos(busqueda: t)),
        ),
        Expanded(
          child: StreamBuilder<List<VehiculoConCliente>>(
            stream: _stream,
            builder: (context, snap) {
              if (!snap.hasData) return const Cargando();
              final lista = snap.data!;
              if (lista.isEmpty) {
                return const Vacio(
                    icono: Icons.no_crash_outlined,
                    texto: 'Sin resultados. Use "Cliente nuevo" para registrarlo.');
              }
              return ListView.separated(
                itemCount: lista.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final x = lista[i];
                  return ListTile(
                    leading: const Icon(Icons.directions_car_outlined),
                    title: Text('${x.vehiculo.matricula} · ${x.vehiculo.marca} ${x.vehiculo.modelo}'),
                    subtitle: Text(x.clienteNombre),
                    trailing: Text('${numero(x.vehiculo.kilometraje)} km'),
                    onTap: () => Navigator.pop(context, x.vehiculo.id),
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
