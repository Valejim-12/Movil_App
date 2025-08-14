import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'inventario_screen.dart';
import 'registrar_entrada_screen.dart';
import 'registrar_salida_screen.dart';
import 'registrar_venta_cable_screen.dart';
import 'historial_entradas_screen.dart';
import 'historial_salidas_screen.dart';
import 'historial_ventas_cable_screen.dart';
import 'historial_alertas_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatelessWidget {
  final String token;
  final String rol;
  final String nombreUsuario;
  final String nombreEmpleado;
  final int userId;

  const HomeScreen({
    Key? key,
    required this.token,
    required this.rol,
    required this.nombreUsuario,
    required this.nombreEmpleado,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistorialAlertasScreen(token: token),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    nombreEmpleado,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    rol,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventario por estante'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventarioScreen(token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.input),
              title: const Text('Registrar entradas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegistrarEntradaScreen(
                      token: token,
                      userId: userId,
                      nombreEmpleado: nombreEmpleado,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.output),
              title: const Text('Registrar salidas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegistrarSalidaScreen(
                      token: token,
                      userId: userId,
                      nombreUsuario: nombreUsuario,
                      nombreEmpleado: nombreEmpleado,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.electrical_services),
              title: const Text('Registrar venta de cable'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegistrarVentaCableScreen(
                      token: token,
                      userId: userId,
                      nombreEmpleado: nombreEmpleado,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de entradas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialEntradasScreen(token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_toggle_off),
              title: const Text('Historial de salidas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialSalidasScreen(token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cable),
              title: const Text('Historial ventas de cable'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialVentasCableScreen(token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PerfilScreen(
                      nombreUsuario: nombreUsuario,
                      rol: rol,
                      nombreEmpleado: nombreEmpleado,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Bienvenido al sistema'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanQrScreen(token: token),
            ),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
