import 'package:flutter/material.dart';
import 'clientes_pantalla.dart';

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
      color: const Color.fromARGB(
        255,
        20,
        39,
        75,
      ), // Changed from white to black
      child: Column(
        children: [
          Container(
            height: 80,
            color: const Color.fromARGB(
              255,
              20,
              39,
              75,
            ), // Changed from teal to black to match the image
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
                  leading: const Icon(Icons.dashboard, color: Colors.white),
                  title: const Text(
                    'Dashboard',
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: selectedItem == 'Dashboard',
                  onTap: () => onItemSelected('Dashboard'),
                ),
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white),
                  title: const Text(
                    'Clientes',
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: selectedItem == 'Clientes',
                  onTap: () => onItemSelected('Clientes'),
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.white),
                  title: const Text(
                    'Productos',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => onItemSelected('Productos'),
                ),
                ListTile(
                  leading: const Icon(Icons.point_of_sale, color: Colors.white),
                  title: const Text(
                    'Ventas',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => onItemSelected('Ventas'),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.white),
                  title: const Text(
                    'Estadísticas',
                    style: TextStyle(color: Colors.white),
                  ),
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
