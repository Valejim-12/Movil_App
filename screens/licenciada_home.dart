import 'package:flutter/material.dart';
import '../models/user.dart';

class LicenciadaHome extends StatelessWidget {
  final User user;
  const LicenciadaHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bienvenida Licenciada')),
      body: Center(child: Text('Hola, ${user.name}')),
    );
  }
}
