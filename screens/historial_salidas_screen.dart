import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class HistorialSalidasScreen extends StatefulWidget {
  final String token;

  const HistorialSalidasScreen({super.key, required this.token});

  @override
  State<HistorialSalidasScreen> createState() => _HistorialSalidasScreenState();
}

class _HistorialSalidasScreenState extends State<HistorialSalidasScreen> {
  List<dynamic> salidas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    obtenerSalidas();
  }

  Future<void> obtenerSalidas() async {
    setState(() => loading = true);
    final url = Uri.parse('${ApiConfig.baseUrl}/api/salidas/historial');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        salidas = data;
        loading = false;
      });
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al obtener salidas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Salidas'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: obtenerSalidas,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : salidas.isEmpty
              ? const Center(child: Text('No hay salidas registradas.'))
              : ListView.builder(
                  itemCount: salidas.length,
                  itemBuilder: (context, index) {
                    final salida = salidas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red, size: 30),
                        title: Text(
                          salida['producto']['nombre'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cantidad: ${salida['cantidad']}'),
                              Text('Fecha: ${salida['fecha']}'),
                              Text('Empleado: ${salida['empleado']}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
