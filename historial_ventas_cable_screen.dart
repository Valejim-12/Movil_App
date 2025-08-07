import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistorialVentasCableScreen extends StatefulWidget {
  final String token;

  const HistorialVentasCableScreen({Key? key, required this.token}) : super(key: key);

  @override
  _HistorialVentasCableScreenState createState() => _HistorialVentasCableScreenState();
}

class _HistorialVentasCableScreenState extends State<HistorialVentasCableScreen> {
  List<dynamic> ventas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerVentasCable();
  }

  Future<void> obtenerVentasCable() async {
    final url = Uri.parse('http://192.168.8.5:8000/api/ventas-cables');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          ventas = data['ventas'];
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar ventas')),
        );
      }
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas de Cable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: obtenerVentasCable,
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ventas.isEmpty
              ? const Center(child: Text('No hay ventas registradas.'))
              : ListView.builder(
                  itemCount: ventas.length,
                  itemBuilder: (context, index) {
                    final venta = ventas[index];
                    final cable = venta['cable'];
                    final usuario = venta['usuario'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(
                          'Cliente: ${venta['cliente']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cable: ${cable != null ? cable['nombre'] : 'N/D'}'),
                            Text('Metros vendidos: ${venta['metros_vendidos']}'),
                            Text('Precio/metro: \$${venta['precio_metro'] ?? 0}'),
                            Text('Descuento: ${venta['descuento']}%'),
                            Text('Total: \$${venta['total'] ?? 0}'),
                            Text('Pagado: \$${venta['monto_pagado'] ?? 0}'),
                            Text('Fecha: ${venta['fecha']}'),
                            Text('Vendedor: ${usuario != null ? usuario['nombre_empleado'] : 'N/D'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
