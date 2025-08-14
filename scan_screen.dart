import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanQrScreen extends StatefulWidget {
  final String token;

  const ScanQrScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool isScanning = true;
  Map<String, dynamic>? producto;
  String mensaje = '';

  Future<void> buscarProducto(String codigo) async {
    setState(() {
      isScanning = false;
    });

    final url = Uri.parse('http://192.168.10.68:8000/api/productos/buscar/$codigo');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        producto = jsonData['producto'];
        mensaje = '';
      });
    } else {
      setState(() {
        producto = null;
        mensaje = 'Producto no encontrado';
      });

      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        mensaje = '';
        isScanning = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Producto')),
      body: Stack(
        children: [
          if (isScanning)
            MobileScanner(
              onDetect: (barcodeCapture) {
                final String? code = barcodeCapture.barcodes.first.rawValue;
                if (code != null && isScanning) {
                  buscarProducto(code);
                }
              },
            ),
          if (!isScanning)
            Container(color: Colors.black.withOpacity(0.6)),
          if (producto != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Nombre: ${producto!['nombre']}'),
                        Text('Cantidad: ${producto!['cantidad_inicial']}'),
                        Text('Estante: ${producto!['estante']['nombre']}'),
                        Text('Ubicación: ${producto!['estante']['categoria']}'),
                        Text('Caducidad: ${producto!['fecha_caducidad']}'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              producto = null;
                              isScanning = true;
                            });
                          },
                          child: const Text('Escanear otro'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (mensaje.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.withOpacity(0.8),
                child: Text(
                  mensaje,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
