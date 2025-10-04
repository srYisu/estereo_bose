import 'package:estereo_bose/pantallas/ventas.dart';
import 'package:estereo_bose/pantallas/ventas_pantalla.dart';
import 'package:flutter/material.dart';
import 'navegacion_widget.dart';
import 'productos_pantalla.dart';
import 'clientes_pantalla.dart';
import 'estadisticas_pantalla.dart';

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
        return  EstadisticasPantalla();
      case 'Clientes':
        return ClientesPage();
      case 'Productos':
        return const ProductosPage();
      case 'Ventas':
        return const VentasPage();
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
