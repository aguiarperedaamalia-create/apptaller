// =============================================================================
// orden_tile.dart — Tarjeta que resume una orden en las listas.
// Muestra lo que el dueño necesita de un vistazo: matrícula, vehículo,
// cliente, mecánico, estado y saldo pendiente. Al tocarla abre el detalle.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../../utils/formato.dart';
import '../comun.dart';
import '../pantallas/orden_detalle.dart';
import '../tema.dart';

class OrdenTile extends StatelessWidget {
  final OrdenResumen orden;
  const OrdenTile(this.orden, {super.key});

  @override
  Widget build(BuildContext context) {
    final o = orden;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE1E6EC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrdenDetallePantalla(ordenId: o.id)),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Franja lateral con el color del estado
            Container(width: 6, color: colorEstado(o.estado)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(o.matricula,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(width: 8),
                    Text('#${o.id}', style: const TextStyle(color: Colores.textoSuave)),
                    const Spacer(),
                    EstadoChip(o.estado, compacto: true),
                  ]),
                  const SizedBox(height: 2),
                  Text(o.vehiculoTexto, style: const TextStyle(fontSize: 15)),
                  Text(o.problema,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colores.textoSuave)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 16, color: Colores.textoSuave),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(o.clienteNombre,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    const Icon(Icons.engineering_outlined, size: 16, color: Colores.textoSuave),
                    const SizedBox(width: 3),
                    Text(o.mecanicoNombre.split(' ').first,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 10),
                    Text(fechaCorta(o.fechaEntrada),
                        style: const TextStyle(fontSize: 13, color: Colores.textoSuave)),
                  ]),
                  if (o.total > 0) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('Total ${dinero(o.total)}', style: const TextStyle(fontSize: 13)),
                      const Spacer(),
                      Text(
                        o.saldo > 0.009 ? 'Debe ${dinero(o.saldo)}' : 'Pagada',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: o.saldo > 0.009 ? Colores.peligro : Colores.exito,
                        ),
                      ),
                    ]),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
