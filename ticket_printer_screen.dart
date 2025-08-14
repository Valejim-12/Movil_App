import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

double asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) {
    final s = v.trim().replaceAll(',', '.');
    return double.tryParse(s) ?? 0.0;
  }
  return 0.0;
}

class TicketLinea {
  final String nombreCable;
  final double metros;
  final double precioMetro;
  final double descuento;

  const TicketLinea({
    required this.nombreCable,
    required this.metros,
    required this.precioMetro,
    this.descuento = 0.0,
  });

  factory TicketLinea.fromApi(Map<String, dynamic> m) {
    return TicketLinea(
      nombreCable: (m['cable']?['nombre'] ?? m['nombreCable'] ?? '-').toString(),
      metros: asDouble(m['metros_vendidos'] ?? m['metros']),
      precioMetro: asDouble(m['precio_metro'] ?? m['precioMetro']),
      descuento: asDouble(m['descuento']),
    );
  }

  double get subtotalBruto => metros * precioMetro;
  double get subtotalNeto {
    final neto = subtotalBruto - descuento;
    return neto < 0 ? 0.0 : neto;
  }
}

class TicketPrinterScreen extends StatelessWidget {
  final String cliente;
  final String nombreEmpleado;

  // Fallback 1 cable
  final String nombreCable;
  final String descripcionCable;
  final double metrosVendidos;
  final double precioMetro;

  final double descuento;
  final double total;

  final double pagado;
  final String noTicket;
  final String fecha;

  final List<TicketLinea> detalles;
  final double? cambio;

  static const String _nombreNegocio = 'GRUPO ROAMSA';
  static const String _rfc        = 'MARF711106FP9';
  static const String _direccion  = '4AV. NORTE ORIENTE #303 B. NORTE\nOCOSINGO, CHIAPAS 29950';
  static const String _telefono   = '9196731076';

  const TicketPrinterScreen({
    Key? key,
    required this.cliente,
    required this.nombreEmpleado,
    required this.nombreCable,
    this.descripcionCable = '',
    required this.metrosVendidos,
    required this.precioMetro,
    required this.descuento,
    required this.total,
    required this.pagado,
    required this.noTicket,
    required this.fecha,
    this.detalles = const [],
    this.cambio,
  }) : super(key: key);

  factory TicketPrinterScreen.fromApi({
    Key? key,
    required dynamic cliente,
    required String nombreEmpleado,
    dynamic nombreCable = '-',
    dynamic descripcionCable = '',
    dynamic metrosVendidos = 0,
    dynamic precioMetro = 0,
    dynamic descuento = 0,
    dynamic total = 0,
    dynamic pagado = 0,
    required dynamic noTicket,
    required dynamic fecha,
    List<dynamic>? detalles,
    dynamic cambio,
  }) {
    final List<TicketLinea> lineas = (detalles ?? [])
        .map((e) => TicketLinea.fromApi((e as Map).cast<String, dynamic>()))
        .toList();

    return TicketPrinterScreen(
      key: key,
      cliente: cliente?.toString() ?? '',
      nombreEmpleado: nombreEmpleado,
      nombreCable: nombreCable?.toString() ?? '-',
      descripcionCable: descripcionCable?.toString() ?? '',
      metrosVendidos: asDouble(metrosVendidos),
      precioMetro: asDouble(precioMetro),
      descuento: asDouble(descuento),
      total: asDouble(total),
      pagado: asDouble(pagado),
      noTicket: noTicket?.toString() ?? '',
      fecha: fecha?.toString() ?? '',
      detalles: lineas,
      cambio: cambio == null ? null : asDouble(cambio),
    );
  }

  double _totalDesdeDetalles() {
    if (detalles.isEmpty) return 0.0;
    final sumaLineas = detalles.fold<double>(0.0, (acc, l) => acc + l.subtotalNeto);
    final totalNeto = (sumaLineas - descuento);
    return totalNeto < 0 ? 0.0 : totalNeto;
  }

  double _totalRecalculado1Cable() {
    final subtotal = metrosVendidos * precioMetro;
    final totalCalc = (subtotal - descuento);
    return totalCalc < 0 ? 0.0 : totalCalc;
  }

  double _totalFinal() {
    if (total > 0) return total;
    if (detalles.isNotEmpty) return _totalDesdeDetalles();
    return _totalRecalculado1Cable();
  }

  double _cambioFinal() {
    final t = _totalFinal();
    if (cambio != null) return cambio!;
    return pagado - t;
  }

  DateTime _resolverFecha() {
    DateTime now = DateTime.now();
    DateTime? parsed;
    try {
      parsed = DateTime.parse(fecha.replaceAll('/', '-'));
    } catch (_) {}
    if (parsed == null) {
      final onlyDateMatch = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fecha.trim());
      if (onlyDateMatch) {
        parsed = DateTime(
          int.parse(fecha.substring(0, 4)),
          int.parse(fecha.substring(5, 7)),
          int.parse(fecha.substring(8, 10)),
          now.hour,
          now.minute,
        );
      }
    }
    if (parsed != null && parsed.hour == 0 && parsed.minute == 0) {
      parsed = DateTime(parsed.year, parsed.month, parsed.day, now.hour, now.minute);
    }
    return parsed ?? now;
  }

  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();

    final DateTime dt = _resolverFecha();
    final String f  = DateFormat('dd/MM/yyyy HH:mm').format(dt);

    const double mm = 2.83465;
    final PdfPageFormat pageFormat = PdfPageFormat(58 * mm, double.infinity, marginAll: 8);

    // --- Estilos reducidos ---
    const double fsHeader = 12.5;
    const double fsStrong = 11.0;
    const double fsBody   = 10.0;
    const double fsSmall  = 9.0;
    const double fsMini   = 8.0;

    pw.TextStyle st([double size = fsBody, bool bold = false]) =>
        pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);

    String money(num n) => "\$${n.toStringAsFixed(2)}";
    String qty(num n) => (n % 1 == 0) ? n.toInt().toString() : n.toStringAsFixed(2);

    pw.Widget sep() => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Container(height: 1, color: PdfColors.black),
        );

    pw.Widget rowTight(String label, String value,
        {double size = fsBody, bool bold = false, double labelWidth = 90}) {
      return pw.Table(
        columnWidths: {
          0: pw.FixedColumnWidth(labelWidth),
          1: const pw.FlexColumnWidth(),
        },
        children: [
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              pw.Text(label, style: st(size, bold), maxLines: 1),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(value, style: st(size, bold)),
              ),
            ],
          ),
        ],
      );
    }

    pw.Widget headerProductos() => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(24),
              1: pw.FlexColumnWidth(),
              2: pw.FixedColumnWidth(66),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Text('CANT', style: st(fsMini, true), maxLines: 1),
                  pw.Text('DESCRIPC.', style: st(fsMini, true), maxLines: 1),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('IMPORTE', style: st(fsMini, true), maxLines: 1),
                  ),
                ],
              ),
            ],
          ),
        );

    pw.Widget productoLinea(TicketLinea l) {
      final cant = qty(l.metros);
      final desc = l.nombreCable; // nombre completo
      final imp  = money(l.subtotalNeto);
      final sub  = (l.descuento > 0)
          ? 'P/metro ${money(l.precioMetro)}   Desc. -${money(l.descuento)}'
          : 'P/metro ${money(l.precioMetro)}';

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(24),
              1: pw.FlexColumnWidth(),
              2: pw.FixedColumnWidth(66),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Text(cant, style: st(fsBody, true)),
                  pw.Text(desc, style: st(fsBody), maxLines: 1, overflow: pw.TextOverflow.clip),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(imp, style: st(fsBody, true)),
                  ),
                ],
              ),
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1.5, bottom: 4),
            child: pw.Text(sub, style: st(fsMini)),
          ),
        ],
      );
    }

    final totalCalc  = _totalFinal();
    final cambioCalc = _cambioFinal();
    final subtotal1  = metrosVendidos * precioMetro;
    final clienteMostrar = cliente.isEmpty ? 'PÚBLICO EN GENERAL' : cliente;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(_nombreNegocio, textAlign: pw.TextAlign.center, style: st(fsHeader, true)),
            pw.Text(_rfc, textAlign: pw.TextAlign.center, style: st(fsSmall)),
            pw.Text(_direccion, textAlign: pw.TextAlign.center, style: st(fsSmall)),
            pw.Text('Tel: $_telefono', textAlign: pw.TextAlign.center, style: st(fsSmall)),
            pw.SizedBox(height: 4),
            pw.Text('Venta de Cable', textAlign: pw.TextAlign.center, style: st(fsStrong, true)),
            pw.Text('Ticket: $noTicket', textAlign: pw.TextAlign.center, style: st(fsSmall)),
            pw.Text('Fecha: $f', textAlign: pw.TextAlign.center, style: st(fsSmall)),
            sep(),

            rowTight('Cliente:', clienteMostrar, size: fsStrong, bold: true, labelWidth: 80),
            sep(),

            pw.Text('Productos', style: st(fsStrong, true)),
            pw.SizedBox(height: 4),
            headerProductos(),
            if (detalles.isNotEmpty)
              ...detalles.map(productoLinea).toList()
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Table(
                    columnWidths: const {
                      0: pw.FixedColumnWidth(24),
                      1: pw.FlexColumnWidth(),
                      2: pw.FixedColumnWidth(66),
                    },
                    children: [
                      pw.TableRow(children: [
                        pw.Text(qty(metrosVendidos), style: st(fsBody, true)),
                        pw.Text(
                          descripcionCable.trim().isNotEmpty ? '$nombreCable — $descripcionCable' : nombreCable,
                          style: st(fsBody),
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                        ),
                        pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(money((subtotal1 - descuento).clamp(0, double.infinity)), style: st(fsBody, true)),
                        ),
                      ])
                    ],
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.5, bottom: 4),
                    child: pw.Text('P/metro ${money(precioMetro)}'
                        '${descuento > 0 ? '   Desc. -${money(descuento)}' : ''}', style: st(fsMini)),
                  ),
                ],
              ),

            sep(),

            if (descuento > 0) rowTight('Descuento', '- ${money(descuento)}'),
            rowTight('TOTAL',  money(totalCalc), size: fsStrong, bold: true),
            rowTight('Pagado', money(pagado),   size: fsStrong),
            rowTight('Cambio', money(cambioCalc), size: fsStrong),

            sep(),

            // Siempre mostrar bloque "PÚBLICO EN GENERAL"
            pw.Text('CLIENTE', textAlign: pw.TextAlign.center, style: st(fsStrong, true)),
            pw.Text('PÚBLICO EN GENERAL', textAlign: pw.TextAlign.center, style: st(fsStrong, true)),
            pw.SizedBox(height: 6),

            pw.Text('¡Gracias por su compra!', textAlign: pw.TextAlign.center, style: st(fsSmall, true)),
            pw.SizedBox(height: 8),

            rowTight('Vendedor:', nombreEmpleado, size: fsStrong, bold: true, labelWidth: 80),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> _print(BuildContext context) async {
    final bytes = await _buildPdf();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _share(BuildContext context) async {
    final bytes = await _buildPdf();
    await Printing.sharePdf(bytes: bytes, filename: 'ticket_$noTicket.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket (PDF)'),
        actions: [
          IconButton(icon: const Icon(Icons.print), tooltip: 'Imprimir', onPressed: () => _print(context)),
          IconButton(icon: const Icon(Icons.ios_share), tooltip: 'Compartir', onPressed: () => _share(context)),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _buildPdf(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return PdfPreview(
            build: (format) async => snap.data!,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName: 'ticket_$noTicket.pdf',
          );
        },
      ),
    );
  }
}
