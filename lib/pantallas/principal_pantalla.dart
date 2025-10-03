import 'package:flutter/material.dart';
import 'navegacion_widget.dart';
import 'productos_pantalla.dart';
import 'clientes_pantalla.dart';

class PrincipalPantalla extends StatefulWidget {
  const PrincipalPantalla({super.key});

  @override
  State<PrincipalPantalla> createState() => _PrincipalPantallaState();
}

class _PrincipalPantallaState extends State<PrincipalPantalla> {
  String _selectedItem = 'Dashboard';

  void _onItemSelected(String item) {
    setState(() {
      _selectedItem = item;
    });
  }

  Widget _getContent() {
    switch (_selectedItem) {
      case 'Dashboard':
        return const Center(child: Text('Dashboard Content'));
      case 'Clientes':
        return ClientesPage();
      case 'Productos':
        return Productos();
      case 'Ventas':
        return const Center(child: Text('Ventas Content'));
      case 'Estadísticas':
        return const Center(child: Text('Estadísticas Content'));
      default:
        return const Center(child: Text('Default Content'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationMenu(
            selectedItem: _selectedItem,
            onItemSelected: _onItemSelected,
          ),
          Expanded(child: _getContent()),
        ],
      ),
    );
  }
}
