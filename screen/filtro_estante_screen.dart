import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/api_config.dart';

class FiltroEstanteScreen extends StatefulWidget {
  final String token;

  const FiltroEstanteScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<FiltroEstanteScreen> createState() => _FiltroEstanteScreenState();
}

class _FiltroEstanteScreenState extends State<FiltroEstanteScreen> {
  List<dynamic> estantes = [];
  List<dynamic> productos = [];
  String? estanteSeleccionado;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    cargarEstantes();
  }

  Future<void> cargarEstantes() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/estantes');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        estantes = jsonDecode(response.body);
      });
    } else {
      print('Error al cargar estantes');
    }
  }

  Future<void> cargarProductosPorEstante(String estanteId) async {
    setState(() {
      cargando = true;
    });

    final url = Uri.parse('${ApiConfig.baseUrl}/productos/por-estante/$estanteId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      },
    );

    setState(() {
      cargando = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        productos = jsonDecode(response.body);
      });
    } else {
      print('Error al cargar productos por estante');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario por Estante'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Selecciona un estante',
                border: OutlineInputBorder(),
              ),
              items: estantes.map<DropdownMenuItem<String>>((estante) {
                return DropdownMenuItem<String>(
                  value: estante['id'].toString(),
                  child: Text(estante['nombre']),
                );
              }).toList(),
              value: estanteSeleccionado,
              onChanged: (valor) {
                setState(() {
                  estanteSeleccionado = valor;
                  productos = [];
                });
                if (valor != null) {
                  cargarProductosPorEstante(valor);
                }
              },
            ),
            const SizedBox(height: 20),
            cargando
                ? const CircularProgressIndicator()
                : Expanded(
                    child: productos.isEmpty
                        ? const Text('No hay productos para mostrar.')
                        : ListView.builder(
                            itemCount: productos.length,
                            itemBuilder: (context, index) {
                              final producto = productos[index];
                              return Card(
                                child: ListTile(
                                  title: Text(producto['nombre']),
                                  subtitle: Text('Cantidad: ${producto['cantidad']}'),
                                  trailing: Text('Caducidad: ${producto['fecha_caducidad'] ?? 'N/A'}'),
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
