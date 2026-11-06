# El Pistón

Aplicación móvil Flutter para el taller automotriz **El Pistón**: clientes, vehículos, órdenes de servicio con su flujo de estados, trabajos de mano de obra, repuestos con inventario, pagos parciales y reportes para el dueño. Funciona **sin conexión** y guarda todo en una base de datos SQLite local con **Drift**.

## Enfoque de UX/UI de esta solución

Interfaz **Material 3 clásica y familiar**, pensada para que cualquier persona del taller la entienda sin explicación: se parece a las apps que ya usa en su teléfono.

- **Navegación:** barra inferior (`NavigationBar`) con 5 secciones fijas: *Inicio, Órdenes, Clientes, Inventario, Reportes*. Se usa `IndexedStack` para que cada pestaña conserve su búsqueda y su scroll.
- **Paleta:** azul petróleo `#12406B` (primario: AppBar, botones), azul oscuro `#0B2A47` (indicadores), naranja pistón `#FF8A00` (acción principal / FAB), fondo `#F3F5F8`, tarjetas `#FFFFFF`, texto `#1B2430` / `#5F6B7A`, éxito `#2E7D32`, peligro `#C62828`, aviso `#EF6C00`. Cada estado de orden tiene color **e icono** propio (el color nunca es la única señal).
- **Tipografía:** **Barlow** (400/500/600/700), sans-serif de inspiración industrial y señalética vial; números grandes y legibles. Incluida en `assets/fonts` (no requiere internet).
- **Formularios en página completa** (`Form` + `TextFormField` con validación) y **diálogos solo para capturas rápidas** (trabajo, pago, cantidad).
- **Detalle de orden en una sola página** con tarjetas (datos, barra de progreso de estados, trabajos, repuestos, pagos, totales) y un **botón fijo abajo** con la siguiente acción del flujo ("Pasar a: En reparación").
- **Nueva orden** en una página con 3 bloques numerados: vehículo (buscar o *cliente nuevo* sin salir del flujo), mecánico (chips con su carga actual; se sugiere el menos cargado) y problema/kilometraje (precargado).
- **Reportes** con `SegmentedButton`: Facturación (atajos Hoy / Esta semana / Este mes / Mes anterior / Elegir…), Deudas, Carga y Stock (lista de compra sugerida).
- Confirmación antes de acciones destructivas, mensajes de error claros de las reglas de negocio y aviso inmediato cuando un repuesto llega a su mínimo.

## Estructura

```
lib/
  main.dart                  arranque, BD, tema, idioma
  data/                      núcleo común (Drift + reglas de negocio)
  utils/formato.dart         dinero, fechas, números
  ui/
    tema.dart                colores, ThemeData, color/icono por estado
    comun.dart               Seccion, EstadoChip, FilaValor, ejecutar(), confirmar()…
    dialogos.dart            DialogoTrabajo, DialogoPago, DialogoCantidad, DialogoTexto
    shell.dart               NavigationBar + IndexedStack
    widgets/orden_tile.dart  tarjeta de orden para listas
    pantallas/               inicio, ordenes, orden_detalle, orden_nueva, seleccion_repuesto,
                             clientes, cliente_detalle, vehiculo_detalle, formularios,
                             inventario, reportes, mecanicos
test/reglas_negocio_test.dart  pruebas con SQLite en memoria
capturas/                    capturas de la app en uso
```

## Cómo ejecutar el proyecto

1. Abrir la carpeta del proyecto en **Android Studio** (con los plugins *Flutter* y *Dart* instalados): `File > Open` y elegir la carpeta que contiene `pubspec.yaml`.
2. Descargar dependencias: `flutter pub get` (o el botón *Pub get* que aparece arriba del `pubspec.yaml`).
3. **Generar el código de Drift** (obligatorio la primera vez y cada vez que se cambie `tablas.dart` o `base_datos.dart`):

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

   Esto crea `lib/data/base_datos.g.dart` (clases `Cliente`, `ClientesCompanion`, `$ClientesTable`, etc.).
4. Elegir un emulador o teléfono Android y pulsar **Run** (`flutter run`).
5. Pruebas de reglas de negocio: `flutter test`.

> Si Android Studio no reconoce la carpeta `android/` (versión de Flutter muy distinta), ejecute `flutter create --platforms=android .` dentro del proyecto: regenera solo los archivos de plataforma que falten y no toca `lib/`.

Primer uso: en el menú de la app está **Cargar datos de ejemplo**, que crea 3 clientes, 4 vehículos y 4 órdenes en distintos estados para probar todas las pantallas.

## Decisiones de diseño comunes (modelo de datos y reglas)

**Tecnología.** Flutter + Dart, persistencia con **Drift** sobre SQLite (paquete `drift_flutter`). La base de datos es un archivo local (`el_piston.sqlite`), así que la app funciona **sin internet** y conserva todo aunque se cierre. No se usa ningún servicio en la nube. Las fuentes tipográficas están incluidas en `assets/fonts` (no se descargan), por la misma razón.

**Arquitectura en capas.**
- `lib/data/tablas.dart`: esquema (8 tablas).
- `lib/data/base_datos.dart`: clase `AppDatabase` (Drift), migración y datos iniciales.
- `lib/data/repositorio_taller.dart`: todas las consultas y **reglas de negocio**. La interfaz nunca escribe SQL.
- `lib/data/modelos.dart`: clases de vista (`OrdenResumen`, `Deudor`, `CargaMecanico`…) y la excepción `ReglaNegocioException`.
- `lib/data/taller_scope.dart`: `InheritedWidget` que entrega el repositorio a todas las pantallas.
- `lib/ui/...`: pantallas y widgets (lo que cambia entre las tres soluciones).

**Reactividad.** Las consultas `watch...()` devuelven `Stream`. Las pantallas usan `StreamBuilder`; al guardar un pago, por ejemplo, el total, el saldo, la lista de deudores y el tablero se actualizan solos sin recargar manualmente.

**Modelo de datos.**

| Tabla | Campos principales | Relación |
|---|---|---|
| clientes | nombre, teléfono, dirección (opcional) | 1 cliente → N vehículos |
| vehiculos | matrícula (única), marca, modelo, año, kilometraje | 1 vehículo → N órdenes |
| mecanicos | nombre, activo | 1 mecánico → N órdenes |
| ordenes | vehículo, mecánico, fecha de entrada, problema, estado, km de entrada, fecha de entrega | |
| trabajos | orden, descripción, precio de mano de obra | 1 orden → N trabajos |
| repuestos | código (único), nombre, precio de venta, existencias, stock mínimo | |
| orden_repuestos | orden, repuesto, cantidad, precio unitario del momento | N:M órdenes–repuestos |
| pagos | orden, monto, fecha, método | 1 orden → N pagos |

**Decisiones tomadas donde el enunciado deja puntos abiertos.**
1. *Estados*: recibida → en diagnóstico → en reparación → lista para entregar → entregada; desde cualquier estado abierto se puede **cancelar**. Se permite retroceder un paso para corregir errores. Al pasar a *entregada* se guarda la fecha de entrega.
2. Las órdenes **entregadas o canceladas no se pueden editar** (trabajos, repuestos, mecánico).
3. Un vehículo **no puede tener dos órdenes abiertas** a la vez.
4. Al crear la orden se registra el **kilometraje de entrada** y se actualiza el "último kilometraje" del vehículo.
5. Al usar un repuesto se valida que haya existencias y se **descuentan en una transacción**. Si se quita de la orden, las unidades vuelven al inventario. Se guarda el **precio del momento** para que el historial no cambie si luego sube el precio.
6. *Stock bajo*: cada repuesto tiene su **stock mínimo** configurable. Si `existencias <= mínimo` aparece en la alerta del inicio y en el reporte; además, al usar un repuesto que cae a ese nivel se muestra un aviso inmediato.
7. *Cancelar*: devuelve los repuestos al inventario. No se permite cancelar una orden con pagos (habría que devolver dinero); primero se eliminan los pagos.
8. *Pagos*: se admiten **pagos parciales** (abonos) en cualquier estado no cancelado; no se puede pagar más que el saldo. Total = mano de obra + repuestos; saldo = total − pagado.
9. *Deuda del cliente*: se cuenta el saldo de las órdenes **terminadas** (lista para entregar o entregada); en las órdenes en proceso el total todavía puede cambiar. Se puede entregar el carro con saldo pendiente (el cliente paga en dos partes).
10. *Facturación de un período*: suma de los totales de las órdenes **entregadas** en el período (desglosado en mano de obra y repuestos), y aparte lo **cobrado** (pagos recibidos) en ese período.
11. Matrículas y códigos de repuesto se guardan en mayúsculas y son únicos. No se borra un cliente con vehículos ni un vehículo con historial.
12. Moneda: CUP. Dos mecánicos precargados (editables) y cinco repuestos de ejemplo.
