import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InventarioScreen extends StatefulWidget {
  final String token;

  const InventarioScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  List<dynamic> estantes = [];
  List<dynamic> productos = [];
  String? estanteSeleccionado;

  final String baseUrl = 'http://192.168.8.5:8000/api'; // IP real

  @override
  void initState() {
    super.initState();
    obtenerEstantes();
  }

  Future<void> obtenerEstantes() async {
    final response = await http.get(Uri.parse('$baseUrl/estantes'));
    if (response.statusCode == 200) {
      setState(() {
        estantes = json.decode(response.body)['estantes'];
      });
    }
  }

  Future<void> obtenerProductos(String estanteId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/productos/por-estante/$estanteId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        productos = json.decode(response.body)['productos'];
      });
    } else {
      setState(() {
        productos = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario por Estante')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: estanteSeleccionado,
              hint: const Text('Selecciona un estante'),
              items: estantes.map<DropdownMenuItem<String>>((estante) {
                return DropdownMenuItem<String>(
                  value: estante['id'].toString(),
                  child: Text(estante['nombre']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  estanteSeleccionado = value!;
                });
                obtenerProductos(value!);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: productos.isEmpty
                  ? const Center(child: Text('No hay productos disponibles'))
                  : ListView.builder(
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        final producto = productos[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(producto['nombre'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Descripción: ${producto['descripcion'] ?? 'N/A'}'),
                                Text('Cantidad: ${producto['cantidad_inicial'] ?? '0'}'),
                                Text('Caducidad: ${producto['fecha_caducidad'] ?? 'N/A'}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
