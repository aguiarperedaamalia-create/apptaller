// =============================================================================
// comun.dart — Widgets y funciones reutilizables de la Solución A.
// Centralizar estos elementos mantiene la interfaz consistente (mismos
// colores, márgenes y mensajes) y evita repetir código en cada pantalla.
// =============================================================================
import 'package:flutter/material.dart';

import '../data/modelos.dart';
import '../data/tablas.dart';
import 'tema.dart';

/// Ejecuta una acción del repositorio y, si falla, muestra el error.
/// Devuelve true si salió bien. Así ninguna pantalla repite try/catch.
Future<bool> ejecutar(BuildContext context, Future<void> Function() accion,
    {String? exito}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await accion();
    if (exito != null) {
      messenger.showSnackBar(SnackBar(content: Text(exito)));
    }
    return true;
  } on ReglaNegocioException catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(e.mensaje),
      backgroundColor: Colores.peligro,
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text('Error inesperado: $e'),
      backgroundColor: Colores.peligro,
    ));
  }
  return false;
}

/// Diálogo de confirmación para acciones destructivas.
Future<bool> confirmar(BuildContext context,
    {required String titulo, required String mensaje, String accion = 'Aceptar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colores.peligro),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(accion),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Etiqueta de estado con icono + texto + color.
class EstadoChip extends StatelessWidget {
  final EstadoOrden estado;
  final bool compacto;
  const EstadoChip(this.estado, {super.key, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final c = colorEstado(estado);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(120)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(iconoEstado(estado), size: compacto ? 14 : 16, color: c),
        const SizedBox(width: 4),
        Text(estado.etiqueta,
            style: TextStyle(
                color: c, fontWeight: FontWeight.w600, fontSize: compacto ? 12 : 13)),
      ]),
    );
  }
}

/// Tarjeta blanca con título, usada para agrupar secciones.
class Seccion extends StatelessWidget {
  final String titulo;
  final IconData? icono;
  final Widget? accion;
  final Widget child;
  const Seccion(
      {super.key, required this.titulo, this.icono, this.accion, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colores.tarjeta,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE1E6EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icono != null) ...[
              Icon(icono, color: Colores.azul, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(titulo,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: Colores.texto)),
            ),
            if (accion != null) accion!,
          ]),
          const SizedBox(height: 6),
          child,
        ]),
      ),
    );
  }
}

/// Fila "concepto ........ valor" para totales.
class FilaValor extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;
  final Color? color;
  const FilaValor(this.etiqueta, this.valor,
      {super.key, this.destacado = false, this.color});

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: destacado ? 18 : 15,
      fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
      color: color ?? Colores.texto,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(etiqueta, style: estilo)),
        Text(valor, style: estilo),
      ]),
    );
  }
}

/// Mensaje para listas vacías.
class Vacio extends StatelessWidget {
  final IconData icono;
  final String texto;
  const Vacio({super.key, required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 56, color: Colores.textoSuave.withAlpha(120)),
        const SizedBox(height: 10),
        Text(texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colores.textoSuave, fontSize: 15)),
      ]),
    );
  }
}

/// Indicador de carga centrado (mientras el Stream no ha emitido).
class Cargando extends StatelessWidget {
  const Cargando({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
}

/// Campo de búsqueda reutilizable.
class CampoBusqueda extends StatelessWidget {
  final String pista;
  final ValueChanged<String> alCambiar;
  const CampoBusqueda({super.key, required this.pista, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: TextField(
        onChanged: alCambiar,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: pista,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
        ),
      ),
    );
  }
}
