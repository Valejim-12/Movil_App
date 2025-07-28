import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class HistorialEntradasScreen extends StatefulWidget {
  final String token;

  const HistorialEntradasScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<HistorialEntradasScreen> createState() => _HistorialEntradasScreenState();
}

class _HistorialEntradasScreenState extends State<HistorialEntradasScreen> {
  List<dynamic> historial = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerHistorial();
  }

  Future<void> obtenerHistorial() async {
    setState(() {
      cargando = true;
    });

    final url = Uri.parse('${ApiConfig.baseUrl}/productos/1/entradas');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}'
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        historial = jsonDecode(response.body);
        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al obtener historial de entradas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Entradas'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: obtenerHistorial,
          )
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : historial.isEmpty
              ? const Center(child: Text('No hay entradas registradas'))
              : ListView.builder(
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final entrada = historial[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text('Producto: ${entrada['producto_nombre']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cantidad: ${entrada['cantidad']}'),
                            Text('Fecha: ${entrada['fecha']}'),
                            Text('Empleado: ${entrada['empleado']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
