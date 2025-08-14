import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';

class RegistrarSalidaScreen extends StatefulWidget {
  final String token;
  final int userId;
  final String nombreUsuario;
  final String nombreEmpleado;

  const RegistrarSalidaScreen({
    Key? key,
    required this.token,
    required this.userId,
    required this.nombreUsuario,
    required this.nombreEmpleado,
  }) : super(key: key);

  @override
  State<RegistrarSalidaScreen> createState() => _RegistrarSalidaScreenState();
}

class _RegistrarSalidaScreenState extends State<RegistrarSalidaScreen> {
  List<dynamic> productos = [];
  int? productoIdSeleccionado;
  int stockDisponible = 0;

  final TextEditingController cantidadController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loadingProductos = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    obtenerProductos();
  }

  Future<void> obtenerProductos() async {
    try {
      setState(() => _loadingProductos = true);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/productos'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          productos = data['productos'] ?? [];
        });
      } else {
        _snack('Error al cargar productos.', error: true);
      }
    } catch (_) {
      if (!mounted) return;
      _snack('Error de conexión al cargar productos.', error: true);
    } finally {
      if (mounted) setState(() => _loadingProductos = false);
    }
  }

  Future<void> registrarSalida() async {
    if (!_formKey.currentState!.validate()) return;
    if (productoIdSeleccionado == null) {
      _snack('Selecciona un producto.', error: true);
      return;
    }

    final cantidad = int.tryParse(cantidadController.text) ?? 0;
    if (cantidad > stockDisponible) {
      _snack('Cantidad mayor al stock disponible.', error: true);
      return;
    }

    setState(() => _enviando = true);

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/salidas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'producto_id': productoIdSeleccionado,
        'cantidad': cantidad,
        'user_id': widget.userId,
        'usuario': widget.nombreUsuario,
        'empleado': widget.nombreEmpleado,
        'fecha': DateTime.now().toIso8601String().substring(0, 10),
      }),
    );

    setState(() => _enviando = false);

    if (response.statusCode == 200) {
      _snack('Salida registrada exitosamente.');
      cantidadController.clear();
      setState(() {
        productoIdSeleccionado = null;
        stockDisponible = 0;
      });
    } else {
      _snack('Error al registrar salida.', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    final bg = error ? Colors.red.shade600 : Colors.green.shade600;
    final icon = error ? Icons.error_outline : Icons.check_circle;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  InputDecoration _fieldDeco({
    required String label,
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.deepPurple, width: 1.6),
      ),
    );
  }

  InputDecoration _dropdownDeco(BuildContext context) {
    return InputDecoration(
      labelText: 'Producto',
      prefixIcon: const Icon(Icons.inventory_2),
      filled: true,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = productos
        .map<DropdownMenuItem<int>>((p) => DropdownMenuItem<int>(
              value: p['id'] as int,
              child: Text(p['nombre']?.toString() ?? ''),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Salida'),
        actions: [
          IconButton(
            tooltip: 'Recargar productos',
            icon: const Icon(Icons.refresh),
            onPressed: _loadingProductos ? null : obtenerProductos,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Dropdown producto
                      DropdownButtonFormField<int>(
                        value: productoIdSeleccionado,
                        items: items,
                        decoration: _dropdownDeco(context),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (value) {
                          setState(() {
                            productoIdSeleccionado = value;
                            final prod = productos.firstWhere(
                              (e) => e['id'] == value,
                              orElse: () => null,
                            );
                            stockDisponible = (prod != null
                                    ? int.tryParse('${prod['cantidad_inicial'] ?? 0}')
                                    : 0) ??
                                0;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Stock visible
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: productoIdSeleccionado == null ? 0.0 : 1.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory, size: 18),
                              const SizedBox(width: 6),
                              Chip(
                                label: Text('Stock: $stockDisponible'),
                                backgroundColor: Colors.blue.withOpacity(.10),
                                side: BorderSide(color: Colors.blue.withOpacity(.25)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Cantidad
                      TextFormField(
                        controller: cantidadController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDeco(
                          label: 'Cantidad',
                          icon: Icons.remove_shopping_cart_outlined,
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Cantidad válida (>0)';
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _enviando ? null : registrarSalida,
                          icon: _enviando
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_alt),
                          label: const Text('Registrar Salida'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            elevation: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
