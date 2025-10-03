import 'package:flutter/material.dart';

class NavigationMenu extends StatelessWidget {
  final String selectedItem;
  final Function(String) onItemSelected;

  const NavigationMenu({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 80,
            color: Colors.teal,
            child: const Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.dashboard, color: Colors.white, size: 36),
                ),
                Text(
                  'Menú',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  selected: selectedItem == 'Dashboard',
                  onTap: () => onItemSelected('Dashboard'),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Clientes'),
                  selected: selectedItem == 'Clientes',
                  onTap: () => onItemSelected('Clientes'),
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text('Productos'),
                  onTap: () => onItemSelected('Productos'),
                ),
                ListTile(
                  leading: const Icon(Icons.point_of_sale),
                  title: const Text('Ventas'),
                  onTap: () => onItemSelected('Ventas'),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Estadísticas'),
                  onTap: () => onItemSelected('Estadísticas'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
