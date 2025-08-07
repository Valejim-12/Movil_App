import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrarEntradaScreen extends StatefulWidget {
  final String token;
  final int userId;

  const RegistrarEntradaScreen({
    Key? key,
    required this.token,
    required this.userId, required String nombreEmpleado,
  }) : super(key: key);

  @override
  State<RegistrarEntradaScreen> createState() => _RegistrarEntradaScreenState();
}

class _RegistrarEntradaScreenState extends State<RegistrarEntradaScreen> {
  final TextEditingController productoIdController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  bool isLoading = false;
  String mensaje = '';

  Future<void> registrarEntrada() async {
    setState(() {
      isLoading = true;
      mensaje = '';
    });

    final url = Uri.parse('http://192.168.8.5:8000/api/entradas');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'producto_id': int.tryParse(productoIdController.text),
        'cantidad': int.tryParse(cantidadController.text),
        'user_id': widget.userId,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        mensaje = json.decode(response.body)['mensaje'] ?? 'Registro exitoso';
        productoIdController.clear();
        cantidadController.clear();
      });
    } else {
      final data = json.decode(response.body);
      setState(() {
        mensaje = data['message'] ?? 'Error al registrar entrada';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Entrada'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: productoIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID del Producto',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : registrarEntrada,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Registrar Entrada'),
            ),
            const SizedBox(height: 20),
            Text(
              mensaje,
              style: TextStyle(
                color: mensaje.contains('correctamente') ? Colors.green : Colors.red,
              ),
            )
          ],
        ),
      ),
    );
  }
}
