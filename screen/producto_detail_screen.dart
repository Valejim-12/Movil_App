import 'package:flutter/material.dart';

class ProductoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> producto;

  const ProductoDetailScreen({Key? key, required this.producto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto['nombre'] ?? 'Nombre desconocido',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Código QR: ${producto['codigo_qr'] ?? 'N/A'}'),
            Text('Cantidad: ${producto['cantidad'] ?? 0}'),
            Text('Estante: ${producto['estante']['nombre'] ?? 'Sin ubicación'}'),
            Text('Fecha de caducidad: ${producto['fecha_caducidad'] ?? 'No especificada'}'),
          ],
        ),
      ),
    );
  }
}
