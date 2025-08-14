import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'ticket_printer_screen.dart'; // Usa TicketLinea y TicketPrinterScreen

// ===== Colores corporativos (Rojo / Azul) =====
const Color roamsaRed = Color(0xFFD32F2F);   // rojo 700
const Color roamsaBlue = Color(0xFF1565C0);  // azul 800

// ------- helpers seguros de conversión -------
double asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) {
    final s = v.trim().replaceAll(',', '.');
    return double.tryParse(s) ?? 0.0;
  }
  return 0.0;
}

int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

class RegistrarVentaCableScreen extends StatefulWidget {
  final String token;
  final int userId;
  final String nombreEmpleado; // mostrado en el ticket

  const RegistrarVentaCableScreen({
    Key? key,
    required this.token,
    required this.userId,
    required this.nombreEmpleado,
  }) : super(key: key);

  @override
  State<RegistrarVentaCableScreen> createState() => _RegistrarVentaCableScreenState();
}

class _RegistrarVentaCableScreenState extends State<RegistrarVentaCableScreen> {
  // Cambia por tu config si la tienes:
  static const String baseUrl = 'http://192.168.10.68:8000/api';

  final _formKey = GlobalKey<FormState>();

  // Cabecera
  final TextEditingController clienteCtrl = TextEditingController();
  final TextEditingController pagadoCtrl = TextEditingController();
  DateTime fecha = DateTime.now();

  // Catálogo
  bool cargandoCables = false;
  List<dynamic> catalogoCables = [];

  // Líneas
  final List<_LineaVenta> lineas = [_LineaVenta()];

  bool enviando = false;

  @override
  void initState() {
    super.initState();
    _obtenerCables();
  }

  @override
  void dispose() {
    clienteCtrl.dispose();
    pagadoCtrl.dispose();
    for (final l in lineas) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _obtenerCables() async {
    setState(() => cargandoCables = true);
    try {
      final uri = Uri.parse('$baseUrl/cables');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final lista = (data['cables'] ?? data['data'] ?? data);
        final List<dynamic> parsed =
            (lista is List) ? lista : ((lista['cables'] is List) ? lista['cables'] : []);
        setState(() => catalogoCables = parsed);
      } else {
        _toast('Error al cargar cables (${resp.statusCode})', success: false);
      }
    } catch (_) {
      _toast('Error de red al cargar cables', success: false);
    } finally {
      if (mounted) setState(() => cargandoCables = false);
    }
  }

  void _agregarLinea() => setState(() => lineas.add(_LineaVenta()));

  void _eliminarLinea(int i) {
    if (lineas.length == 1) {
      _toast('Debe existir al menos una línea', success: false);
      return;
    }
    setState(() {
      lineas[i].dispose();
      lineas.removeAt(i);
    });
  }

  double _precioDeCable(dynamic c) {
    final pm = c['precio_metro'] ?? c['precio_por_metro'];
    return asDouble(pm);
  }

  String _nombreDeCable(dynamic c) => c['nombre']?.toString() ?? 'Cable';

  dynamic _buscarCablePorId(int? id) {
    if (id == null) return null;
    try {
      return catalogoCables.firstWhere((e) => asInt(e['id']) == id);
    } catch (_) {
      return null;
    }
  }

  double _subtotalLinea(_LineaVenta l) {
    final cb = _buscarCablePorId(l.cableId);
    final precio = cb == null ? 0.0 : _precioDeCable(cb);
    final metros = asDouble(l.metrosCtrl.text);
    final desc = asDouble(l.descuentoCtrl.text);
    final bruto = metros * precio;
    final neto = bruto - desc;
    return neto < 0 ? 0.0 : neto;
  }

  double _totalMetros() {
    return lineas.fold(0.0, (s, l) => s + asDouble(l.metrosCtrl.text));
  }

  double _totalVentaAprox() {
    // Ya NO hay descuento global: solo suma de líneas (cada una con su descuento)
    return lineas.fold(0.0, (s, l) => s + _subtotalLinea(l));
  }

  Future<void> _seleccionarFecha() async {
    final sel = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (sel != null) setState(() => fecha = sel);
  }

  bool _validar() {
    if (!_formKey.currentState!.validate()) return false;
    for (final l in lineas) {
      if (l.cableId == null) {
        _toast('Selecciona un cable en cada línea', success: false);
        return false;
      }
    }
    final p = asDouble(pagadoCtrl.text);
    if (p <= 0) {
      _toast('Ingresa el monto pagado', success: false);
      return false;
    }
    return true;
  }

  String _generarNoTicket() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'TKT-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Future<void> _enviarVenta() async {
    if (!_validar()) return;

    setState(() => enviando = true);
    const double descuentoGlobal = 0.0; // eliminado; mantenemos 0 para el ticket
    final pagado = asDouble(pagadoCtrl.text);

    final items = lineas.map((l) {
      final metros = asDouble(l.metrosCtrl.text);
      final desc = asDouble(l.descuentoCtrl.text);
      return {
        'cable_id': l.cableId,
        'metros': metros, // tu backend lo normaliza
        'descuento': desc,
      };
    }).toList();

    final payloadLote = {
      'user_id': widget.userId,
      'cliente': clienteCtrl.text.trim(),
      'fecha': fecha.toIso8601String().split('T').first,
      'pagado': pagado,
      'items': items,
    };

    dynamic dataLote;
    final uriLote = Uri.parse('$baseUrl/ventas-cables/multiples');

    try {
      // 1) Endpoint múltiple
      final respLote = await http.post(
        uriLote,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode(payloadLote),
      );

      if (respLote.statusCode == 200 || respLote.statusCode == 201) {
        dataLote = json.decode(respLote.body);
        await _irATicketDesdeRespuestaLote(
          dataLote: dataLote,
          descuentoGlobal: descuentoGlobal,
          pagado: pagado,
        );
        _toast('¡Venta registrada!', success: true);
        return;
      }

      // 2) Fallback: crear una por una
      final uri = Uri.parse('$baseUrl/ventas-cables');
      final respuestas = <Map<String, dynamic>>[];
      for (final it in items) {
        final body = {
          'user_id': widget.userId,
          'cliente': payloadLote['cliente'],
          'fecha': payloadLote['fecha'],
          'cable_id': it['cable_id'],
          'metros': it['metros'],
          'descuento': it['descuento'],
          'pagado': pagado,
        };

        final r = await http.post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode(body),
        );

        if (r.statusCode == 200 || r.statusCode == 201) {
          respuestas.add(json.decode(r.body));
        } else if (r.statusCode == 422) {
          final d = json.decode(r.body);
          _toast('Error en una línea: ${d['errors'] ?? 'Validación inválida'}', success: false);
          setState(() => enviando = false);
          return;
        } else if (r.statusCode == 401) {
          _toast('No autenticado. Revisa tu token.', success: false);
          setState(() => enviando = false);
          return;
        } else {
          _toast('Error al registrar una línea (${r.statusCode})', success: false);
          setState(() => enviando = false);
          return;
        }
      }

      await _irATicketDesdeRespuestasIndividuales(
        respuestas: respuestas,
        descuentoGlobal: descuentoGlobal,
        pagado: pagado,
      );
      _toast('¡Venta registrada!', success: true);
    } catch (_) {
      _toast('Error de red al registrar', success: false);
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  // ---- Ticket desde venta grupal ----
  Future<void> _irATicketDesdeRespuestaLote({
    required dynamic dataLote,
    required double descuentoGlobal,
    required double pagado,
  }) async {
    final venta = (dataLote is Map && dataLote['venta_grupal'] != null)
        ? dataLote['venta_grupal']
        : (dataLote is Map && dataLote['venta'] != null)
            ? dataLote['venta']
            : dataLote;

    List<dynamic> items = [];
    if (venta is Map && venta['items'] is List) items = venta['items'];

    final detalles = <TicketLinea>[];
    if (items.isNotEmpty) {
      for (final it in items) {
        final nombre = it['cable']?['nombre']?.toString() ??
            it['nombre_cable']?.toString() ??
            'Cable';
        final metros = asDouble(it['metros_vendidos'] ?? it['metros']);
        final precioMetro =
            asDouble(it['precio_metro'] ?? it['cable']?['precio_metro'] ?? it['cable']?['precio_por_metro']);
        final descLinea = asDouble(it['descuento']);

        detalles.add(TicketLinea(
          nombreCable: nombre,
          metros: metros,
          precioMetro: precioMetro,
          descuento: descLinea,
        ));
      }
    } else {
      for (final l in lineas) {
        final cb = _buscarCablePorId(l.cableId);
        final nombre = cb == null ? 'Cable' : _nombreDeCable(cb);
        final precio = cb == null ? 0.0 : _precioDeCable(cb);
        final metros = asDouble(l.metrosCtrl.text);
        final descLinea = asDouble(l.descuentoCtrl.text);
        detalles.add(TicketLinea(
          nombreCable: nombre,
          metros: metros,
          precioMetro: precio,
          descuento: descLinea,
        ));
      }
    }

    final cliente = (venta is Map && venta['cliente'] != null)
        ? venta['cliente'].toString()
        : clienteCtrl.text.trim();

    final total = (venta is Map) ? asDouble(venta['total']) : 0.0;
    final noTicket = (venta is Map && venta['no_ticket'] != null)
        ? venta['no_ticket'].toString()
        : _generarNoTicket();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketPrinterScreen(
          cliente: cliente,
          nombreEmpleado: widget.nombreEmpleado,
          // Ignorados cuando 'detalles' trae datos
          nombreCable: detalles.isNotEmpty ? detalles.first.nombreCable : 'Cable',
          metrosVendidos: detalles.isNotEmpty ? detalles.first.metros : 0,
          precioMetro: detalles.isNotEmpty ? detalles.first.precioMetro : 0,
          descuento: descuentoGlobal, // 0
          total: total,
          pagado: pagado,
          noTicket: noTicket,
          fecha: (venta is Map && venta['fecha'] != null)
              ? venta['fecha'].toString()
              : fecha.toIso8601String().split('T').first,
          detalles: detalles,
        ),
      ),
    );
  }

  // ---- Ticket desde múltiples respuestas ----
  Future<void> _irATicketDesdeRespuestasIndividuales({
    required List<Map<String, dynamic>> respuestas,
    required double descuentoGlobal,
    required double pagado,
  }) async {
    final detalles = <TicketLinea>[];
    String cliente = clienteCtrl.text.trim();

    for (final r in respuestas) {
      final v = (r['venta'] != null) ? r['venta'] : r;
      if (v is Map && v['cliente'] != null) cliente = v['cliente'].toString();

      final nombre = v['cable']?['nombre']?.toString() ?? 'Cable';
      final metros = asDouble(v['metros_vendidos'] ?? v['metros']);
      final precio = asDouble(v['precio_metro'] ?? v['cable']?['precio_metro'] ?? v['cable']?['precio_por_metro']);
      final descLinea = asDouble(v['descuento']);

      detalles.add(TicketLinea(
        nombreCable: nombre,
        metros: metros,
        precioMetro: precio,
        descuento: descLinea,
      ));
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketPrinterScreen(
          cliente: cliente,
          nombreEmpleado: widget.nombreEmpleado,
          nombreCable: detalles.isNotEmpty ? detalles.first.nombreCable : 'Cable',
          metrosVendidos: detalles.isNotEmpty ? detalles.first.metros : 0,
          precioMetro: detalles.isNotEmpty ? detalles.first.precioMetro : 0,
          descuento: descuentoGlobal, // 0
          total: 0, // recalcula en ticket con detalles
          pagado: pagado,
          noTicket: _generarNoTicket(),
          fecha: fecha.toIso8601String().split('T').first,
          detalles: detalles,
        ),
      ),
    );
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    final shapeCard = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final borderBlue = OutlineInputBorder(
      borderSide: const BorderSide(color: roamsaBlue, width: 1.2),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta de cable'),
        backgroundColor: roamsaRed,
        actions: [
          IconButton(
            tooltip: 'Actualizar catálogo',
            icon: const Icon(Icons.refresh),
            onPressed: cargandoCables ? null : _obtenerCables,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 37, 121, 217),
        onPressed: _agregarLinea,
        icon: const Icon(Icons.add),
        label: const Text('Agregar línea'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ===== Cabecera =====
            _card(
              shapeCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tituloSeccion(Icons.person, 'Datos del cliente'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: clienteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Cliente',
                      filled: true,
                      border: borderBlue,
                      enabledBorder: borderBlue,
                      prefixIcon: const Icon(Icons.person_outline, color: roamsaBlue),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ingrese el nombre del cliente' : null,
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha',
                      filled: true,
                      border: borderBlue,
                      enabledBorder: borderBlue,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
                          style: tema.textTheme.bodyLarge,
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: roamsaBlue),
                          onPressed: _seleccionarFecha,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Cambiar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===== Líneas =====
            _card(
              shapeCard,
              child: Column(
                children: [
                  _tituloSeccion(Icons.cable, 'Líneas de venta'),
                  const SizedBox(height: 8),

                  ...List.generate(lineas.length, (i) {
                    final l = lineas[i];
                    final subtotal = _subtotalLinea(l);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: roamsaBlue.withOpacity(0.25)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Cable',
                                      filled: true,
                                      border: borderBlue,
                                      enabledBorder: borderBlue,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        isExpanded: true,
                                        value: l.cableId,
                                        hint: const Text('Selecciona un cable'),
                                        items: catalogoCables.map<DropdownMenuItem<int>>((c) {
                                          final id = asInt(c['id'])!;
                                          final nombre = _nombreDeCable(c);
                                          final precio = _precioDeCable(c);
                                          final sub = (precio > 0)
                                              ? ' • \$${precio.toStringAsFixed(2)}/m'
                                              : '';
                                          return DropdownMenuItem<int>(
                                            value: id,
                                            child: Text('$nombre$sub'),
                                          );
                                        }).toList(),
                                        onChanged: (v) => setState(() => l.cableId = v),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Eliminar línea',
                                  onPressed: () => _eliminarLinea(i),
                                  icon: const Icon(Icons.delete_outline),
                                  color: roamsaRed,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: l.metrosCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Metros',
                                      hintText: '',
                                      filled: true,
                                      border: borderBlue,
                                      enabledBorder: borderBlue,
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true, signed: false),
                                    validator: (v) {
                                      final n = asDouble(v);
                                      if (n <= 0) return 'Número inválido';
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: l.descuentoCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Desc. línea',
                                      hintText: '0.0',
                                      filled: true,
                                      border: borderBlue,
                                      enabledBorder: borderBlue,
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true, signed: false),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                                style: tema.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: roamsaRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===== Resumen y pago (sin descuento global) =====
            _card(
              shapeCard,
              child: Column(
                children: [
                  _tituloSeccion(Icons.receipt_long, 'Resumen y pago'),
                  const SizedBox(height: 8),

                  _filaTotal('Total metros:', _totalMetros().toStringAsFixed(2), tema),
                  const SizedBox(height: 6),
                  _filaTotal('Total a pagar (aprox):',
                      '\$${_totalVentaAprox().toStringAsFixed(2)}', tema),
                  const Divider(height: 24),

                  TextFormField(
                    controller: pagadoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Pagado por el cliente',
                      hintText: '',
                      filled: true,
                      border: borderBlue,
                      enabledBorder: borderBlue,
                      prefixIcon: const Icon(Icons.payments_outlined, color: roamsaBlue),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: false),
                    validator: (v) {
                      final n = asDouble(v);
                      if (n <= 0) return 'Ingresa el monto pagado';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: roamsaRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: enviando ? null : _enviarVenta,
                icon: enviando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(enviando ? 'Guardando venta...' : 'Guardar venta y generar ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helpers UI =====
  Widget _card(ShapeBorder shape, {required Widget child}) {
    return Card(
      elevation: 1.6,
      shape: shape,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _tituloSeccion(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 20, color: roamsaBlue),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.w800, color: roamsaBlue),
        ),
      ],
    );
  }

  Widget _filaTotal(String titulo, String valor, ThemeData tema) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: tema.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: roamsaBlue,
          ),
        ),
        Text(
          valor,
          style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// ===== Snack personalizado (éxito / error) =====
  void _toast(String msg, {bool success = true}) {
    final sc = ScaffoldMessenger.of(context);
    sc.clearSnackBars();

    final Color bgColor = success ? Colors.green.shade600 : roamsaRed;
    final IconData icon = success ? Icons.check_circle_outline : Icons.error_outline;

    sc.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bgColor,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// --------- Modelo interno de línea en el formulario ---------
class _LineaVenta {
  int? cableId;
  final TextEditingController metrosCtrl = TextEditingController();
  final TextEditingController descuentoCtrl = TextEditingController(text: '0');

  void dispose() {
    metrosCtrl.dispose();
    descuentoCtrl.dispose();
  }
}
