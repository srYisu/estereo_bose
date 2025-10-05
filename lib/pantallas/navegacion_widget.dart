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
      color: const Color.fromARGB(255, 20, 39, 75),
      child: Column(
        children: [
          Container(
            height: 80,
            color: const Color.fromARGB(255, 20, 39, 75),
            child: const Row(
              children: [
                Padding(padding: EdgeInsets.all(16)),
                Text(
                  'Menú',
                  style: TextStyle(color: Colors.white, fontSize: 28),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildMenuTile(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  selected: selectedItem == 'Dashboard',
                  onTap: () => onItemSelected('Dashboard'),
                ),
                _buildMenuTile(
                  icon: Icons.home,
                  label: 'Clientes',
                  selected: selectedItem == 'Clientes',
                  onTap: () => onItemSelected('Clientes'),
                ),
                _buildMenuTile(
                  icon: Icons.shopping_bag,
                  label: 'Productos',
                  selected: selectedItem == 'Productos',
                  onTap: () => onItemSelected('Productos'),
                ),
                _buildMenuTile(
                  icon: Icons.point_of_sale,
                  label: 'Ventas',
                  selected: selectedItem == 'Ventas',
                  onTap: () => onItemSelected('Ventas'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: Color(0xFF2C3E5A), width: 1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Icon(icon, color: Colors.white, size: 35),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        selected: selected,
        onTap: onTap,
        horizontalTitleGap: 16,
        minLeadingWidth: 0,
      ),
    );
  }
}
