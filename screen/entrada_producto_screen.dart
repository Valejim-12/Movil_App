import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';


class RegistrarEntradasScreen extends StatefulWidget {
  final String token;

  const RegistrarEntradasScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<RegistrarEntradasScreen> createState() => _RegistrarEntradasScreenState();
}

class _RegistrarEntradasScreenState extends State<RegistrarEntradasScreen> {
  final TextEditingController _codigoQRController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  String mensaje = '';
  bool cargando = false;

  Future<void> registrarEntrada() async {
    final codigoQR = _codigoQRController.text.trim();
    final cantidad = _cantidadController.text.trim();

    if (codigoQR.isEmpty || cantidad.isEmpty) {
      setState(() {
        mensaje = 'Por favor llena todos los campos.';
      });
      return;
    }

    setState(() {
      cargando = true;
      mensaje = '';
    });

    final url = Uri.parse('${ApiConfig.baseUrl}/entradas');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'codigo_qr': codigoQR,
        'cantidad': int.tryParse(cantidad),
      }),
    );

    setState(() {
      cargando = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        mensaje = 'Entrada registrada correctamente.';
        _codigoQRController.clear();
        _cantidadController.clear();
      });
    } else {
      setState(() {
        mensaje = 'Error al registrar la entrada.';
      });
    }
  }

  @override
  void dispose() {
    _codigoQRController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Entrada de Producto'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codigoQRController,
              decoration: const InputDecoration(
                labelText: 'Código QR del producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: cargando ? null : registrarEntrada,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Registrar Entrada'),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: TextStyle(
                color: mensaje.contains('correctamente') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
