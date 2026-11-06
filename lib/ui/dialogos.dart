// =============================================================================
// dialogos.dart — Diálogos pequeños de captura rápida (Solución A).
// Cada diálogo es un StatefulWidget que crea y DESTRUYE (dispose) sus propios
// TextEditingController, y devuelve el resultado con Navigator.pop(valor).
// Los formularios grandes (cliente, vehículo, repuesto) van en páginas
// completas (formularios.dart).
// =============================================================================
import 'package:flutter/material.dart';

import '../data/base_datos.dart';
import '../utils/formato.dart';

/// Resultado de capturar un trabajo de mano de obra.
class DatosTrabajo {
  final String descripcion;
  final double precio;
  const DatosTrabajo(this.descripcion, this.precio);
}

/// Trabajos frecuentes: un toque rellena la descripción (menos escritura).
const _trabajosFrecuentes = [
  'Cambio de aceite',
  'Alineación',
  'Balanceo',
  'Cambio de pastillas de freno',
  'Diagnóstico eléctrico',
  'Afinación de motor',
];

class DialogoTrabajo extends StatefulWidget {
  const DialogoTrabajo({super.key});
  @override
  State<DialogoTrabajo> createState() => _DialogoTrabajoState();
}

class _DialogoTrabajoState extends State<DialogoTrabajo> {
  final _form = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _precio = TextEditingController();

  @override
  void dispose() {
    _desc.dispose();
    _precio.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, DatosTrabajo(_desc.text.trim(), leerDinero(_precio.text)!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar trabajo'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final t in _trabajosFrecuentes)
                ActionChip(label: Text(t), onPressed: () => _desc.text = t),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Descripción'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _precio,
              decoration: const InputDecoration(labelText: 'Mano de obra', suffixText: kMoneda),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = leerDinero(v ?? '');
                if (n == null) return 'Número inválido';
                if (n < 0) return 'No puede ser negativo';
                return null;
              },
              onFieldSubmitted: (_) => _guardar(),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Agregar')),
      ],
    );
  }
}

/// Resultado de capturar un pago.
class DatosPago {
  final double monto;
  final String metodo;
  const DatosPago(this.monto, this.metodo);
}

class DialogoPago extends StatefulWidget {
  final double saldo;
  const DialogoPago({super.key, required this.saldo});
  @override
  State<DialogoPago> createState() => _DialogoPagoState();
}

class _DialogoPagoState extends State<DialogoPago> {
  final _form = GlobalKey<FormState>();
  final _monto = TextEditingController();
  String _metodo = 'Efectivo';

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, DatosPago(leerDinero(_monto.text)!, _metodo));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Saldo pendiente: ${dinero(widget.saldo)}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _monto,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Monto',
              suffixIcon: TextButton(
                onPressed: () => _monto.text = widget.saldo.toStringAsFixed(2),
                child: const Text('Todo'),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final n = leerDinero(v ?? '');
              if (n == null || n <= 0) return 'Ingrese un monto mayor que 0';
              if (n > widget.saldo + 0.009) return 'Supera el saldo';
              return null;
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Efectivo', label: Text('Efectivo'), icon: Icon(Icons.payments_outlined)),
              ButtonSegment(value: 'Transferencia', label: Text('Transf.'), icon: Icon(Icons.phone_android)),
            ],
            selected: {_metodo},
            onSelectionChanged: (s) => setState(() => _metodo = s.first),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Registrar')),
      ],
    );
  }
}

/// Pide una cantidad entera entre 1 y [maximo].
class DialogoCantidad extends StatefulWidget {
  final String titulo;
  final int maximo;
  const DialogoCantidad({super.key, required this.titulo, required this.maximo});
  @override
  State<DialogoCantidad> createState() => _DialogoCantidadState();
}

class _DialogoCantidadState extends State<DialogoCantidad> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Disponibles: ${widget.maximo}'),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton.filledTonal(
            onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 70,
            child: Text('$_cantidad',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          ),
          IconButton.filledTonal(
            onPressed: _cantidad < widget.maximo ? () => setState(() => _cantidad++) : null,
            icon: const Icon(Icons.add),
          ),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, _cantidad), child: const Text('Aceptar')),
      ],
    );
  }
}

/// Edita un texto (p. ej. el problema reportado).
class DialogoTexto extends StatefulWidget {
  final String titulo;
  final String inicial;
  const DialogoTexto({super.key, required this.titulo, required this.inicial});
  @override
  State<DialogoTexto> createState() => _DialogoTextoState();
}

class _DialogoTextoState extends State<DialogoTexto> {
  late final _c = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(controller: _c, maxLines: 4, minLines: 2, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _c.text.trim()), child: const Text('Guardar')),
      ],
    );
  }
}

/// Elige un mecánico de la lista.
Future<int?> elegirMecanico(BuildContext context, List<Mecanico> mecanicos, int actual) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Asignar mecánico'),
      children: [
        for (final m in mecanicos)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, m.id),
            child: Row(children: [
              Icon(m.id == actual ? Icons.radio_button_checked : Icons.radio_button_off),
              const SizedBox(width: 10),
              Text(m.nombre, style: const TextStyle(fontSize: 16)),
            ]),
          ),
      ],
    ),
  );
}
