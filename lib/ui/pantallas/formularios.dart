// =============================================================================
// formularios.dart — Formularios de alta/edición en página completa
// (Solución A): cliente, vehículo y repuesto.
// Patrón: Form + GlobalKey<FormState> + TextFormField con validator.
// Al guardar se llama al repositorio; si una regla de negocio falla (por
// ejemplo, matrícula repetida) se muestra el mensaje y NO se cierra la página.
// Cada página devuelve el id guardado con Navigator.pop(context, id).
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';

/// Esqueleto común: AppBar + formulario desplazable + botón Guardar fijo abajo.
class _PaginaFormulario extends StatelessWidget {
  final String titulo;
  final GlobalKey<FormState> formKey;
  final List<Widget> campos;
  final VoidCallback? alGuardar;
  final bool guardando;
  const _PaginaFormulario({
    required this.titulo,
    required this.formKey,
    required this.campos,
    required this.alGuardar,
    required this.guardando,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final c in campos) Padding(padding: const EdgeInsets.only(bottom: 14), child: c),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: guardando ? null : alGuardar,
            icon: guardando
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
          ),
        ),
      ),
    );
  }
}

String? _obligatorio(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

/// Guarda con el repositorio y cierra devolviendo el id; si falla, avisa.
Future<void> _guardarYSalir(
    State estado, Future<int> Function() accion, void Function(bool) marcar) async {
  final context = estado.context;
  final messenger = ScaffoldMessenger.of(context);
  marcar(true);
  try {
    final id = await accion();
    if (estado.mounted) Navigator.of(estado.context).pop(id);
  } on ReglaNegocioException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: Colores.peligro));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colores.peligro));
  } finally {
    if (estado.mounted) marcar(false);
  }
}

// =============================================================================
// CLIENTE
// =============================================================================
class ClienteFormPantalla extends StatefulWidget {
  final Cliente? cliente; // null = nuevo
  const ClienteFormPantalla({super.key, this.cliente});

  @override
  State<ClienteFormPantalla> createState() => _ClienteFormPantallaState();
}

class _ClienteFormPantallaState extends State<ClienteFormPantalla> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.cliente?.nombre);
  late final _telefono = TextEditingController(text: widget.cliente?.telefono);
  late final _direccion = TextEditingController(text: widget.cliente?.direccion);
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _direccion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final repo = TallerScope.of(context);
    final c = widget.cliente;
    _guardarYSalir(this, () async {
      if (c == null) {
        return repo.crearCliente(
            nombre: _nombre.text, telefono: _telefono.text, direccion: _direccion.text);
      }
      await repo.actualizarCliente(c.id,
          nombre: _nombre.text, telefono: _telefono.text, direccion: _direccion.text);
      return c.id;
    }, (v) => setState(() => _guardando = v));
  }

  @override
  Widget build(BuildContext context) {
    return _PaginaFormulario(
      titulo: widget.cliente == null ? 'Nuevo cliente' : 'Editar cliente',
      formKey: _form,
      guardando: _guardando,
      alGuardar: _guardar,
      campos: [
        TextFormField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre y apellidos', prefixIcon: Icon(Icons.person)),
          validator: _obligatorio,
        ),
        TextFormField(
          controller: _telefono,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
          validator: (v) {
            if (_obligatorio(v) != null) return 'Campo obligatorio';
            return RegExp(r'^[0-9+\-\s]{6,20}$').hasMatch(v!.trim())
                ? null
                : 'Solo dígitos, mínimo 6';
          },
        ),
        TextFormField(
          controller: _direccion,
          decoration: const InputDecoration(
              labelText: 'Dirección (opcional)', prefixIcon: Icon(Icons.home_outlined)),
        ),
      ],
    );
  }
}

// =============================================================================
// VEHÍCULO
// =============================================================================
class VehiculoFormPantalla extends StatefulWidget {
  final int clienteId;
  final Vehiculo? vehiculo; // null = nuevo
  const VehiculoFormPantalla({super.key, required this.clienteId, this.vehiculo});

  @override
  State<VehiculoFormPantalla> createState() => _VehiculoFormPantallaState();
}

class _VehiculoFormPantallaState extends State<VehiculoFormPantalla> {
  final _form = GlobalKey<FormState>();
  late final _matricula = TextEditingController(text: widget.vehiculo?.matricula);
  late final _marca = TextEditingController(text: widget.vehiculo?.marca);
  late final _modelo = TextEditingController(text: widget.vehiculo?.modelo);
  late final _anio = TextEditingController(text: widget.vehiculo?.anio.toString());
  late final _km = TextEditingController(text: widget.vehiculo?.kilometraje.toString() ?? '0');
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_matricula, _marca, _modelo, _anio, _km]) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final repo = TallerScope.of(context);
    final v = widget.vehiculo;
    final anio = leerEntero(_anio.text)!;
    final km = leerEntero(_km.text)!;
    _guardarYSalir(this, () async {
      if (v == null) {
        return repo.crearVehiculo(
            clienteId: widget.clienteId,
            matricula: _matricula.text,
            marca: _marca.text,
            modelo: _modelo.text,
            anio: anio,
            kilometraje: km);
      }
      await repo.actualizarVehiculo(v.id,
          matricula: _matricula.text,
          marca: _marca.text,
          modelo: _modelo.text,
          anio: anio,
          kilometraje: km);
      return v.id;
    }, (x) => setState(() => _guardando = x));
  }

  @override
  Widget build(BuildContext context) {
    final maxAnio = DateTime.now().year + 1;
    return _PaginaFormulario(
      titulo: widget.vehiculo == null ? 'Nuevo vehículo' : 'Editar vehículo',
      formKey: _form,
      guardando: _guardando,
      alGuardar: _guardar,
      campos: [
        TextFormField(
          controller: _matricula,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Matrícula', prefixIcon: Icon(Icons.pin_outlined)),
          validator: _obligatorio,
        ),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _marca,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Marca'),
              validator: _obligatorio,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _modelo,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Modelo'),
              validator: _obligatorio,
            ),
          ),
        ]),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _anio,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Año'),
              validator: (t) {
                final n = leerEntero(t ?? '');
                if (n == null) return 'Inválido';
                if (n < 1900 || n > maxAnio) return '1900–$maxAnio';
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _km,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kilometraje', suffixText: 'km'),
              validator: (t) {
                final n = leerEntero(t ?? '');
                return (n == null || n < 0) ? 'Inválido' : null;
              },
            ),
          ),
        ]),
      ],
    );
  }
}

// =============================================================================
// REPUESTO
// =============================================================================
class RepuestoFormPantalla extends StatefulWidget {
  final Repuesto? repuesto; // null = nuevo
  const RepuestoFormPantalla({super.key, this.repuesto});

  @override
  State<RepuestoFormPantalla> createState() => _RepuestoFormPantallaState();
}

class _RepuestoFormPantallaState extends State<RepuestoFormPantalla> {
  final _form = GlobalKey<FormState>();
  late final _codigo = TextEditingController(text: widget.repuesto?.codigo);
  late final _nombre = TextEditingController(text: widget.repuesto?.nombre);
  late final _precio = TextEditingController(text: widget.repuesto?.precioVenta.toStringAsFixed(2));
  late final _exist = TextEditingController(text: '${widget.repuesto?.existencias ?? 0}');
  late final _minimo = TextEditingController(text: '${widget.repuesto?.stockMinimo ?? 3}');
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_codigo, _nombre, _precio, _exist, _minimo]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _entero(String? t) {
    final n = leerEntero(t ?? '');
    return (n == null || n < 0) ? 'Inválido' : null;
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final repo = TallerScope.of(context);
    final r = widget.repuesto;
    _guardarYSalir(this, () async {
      await repo.guardarRepuesto(
        id: r?.id,
        codigo: _codigo.text,
        nombre: _nombre.text,
        precioVenta: leerDinero(_precio.text)!,
        existencias: leerEntero(_exist.text)!,
        stockMinimo: leerEntero(_minimo.text)!,
      );
      return r?.id ?? 0;
    }, (x) => setState(() => _guardando = x));
  }

  @override
  Widget build(BuildContext context) {
    return _PaginaFormulario(
      titulo: widget.repuesto == null ? 'Nuevo repuesto' : 'Editar repuesto',
      formKey: _form,
      guardando: _guardando,
      alGuardar: _guardar,
      campos: [
        TextFormField(
          controller: _codigo,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Código', prefixIcon: Icon(Icons.qr_code)),
          validator: _obligatorio,
        ),
        TextFormField(
          controller: _nombre,
          decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.label_outline)),
          validator: _obligatorio,
        ),
        TextFormField(
          controller: _precio,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Precio de venta', suffixText: kMoneda),
          validator: (t) {
            final n = leerDinero(t ?? '');
            return (n == null || n < 0) ? 'Inválido' : null;
          },
        ),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _exist,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Existencias'),
              validator: _entero,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _minimo,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Stock mínimo', helperText: 'Avisa al llegar aquí'),
              validator: _entero,
            ),
          ),
        ]),
      ],
    );
  }
}
