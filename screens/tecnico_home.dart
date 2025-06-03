import 'package:flutter/material.dart';
import '../models/user.dart';

class TecnicoHome extends StatelessWidget {
  final User user;
  const TecnicoHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bienvenido Técnico')),
      body: Center(child: Text('Hola, ${user.name}')),
    );
  }
}
