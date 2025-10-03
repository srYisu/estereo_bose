import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:estereo_bose/db/metodosClientes.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final Metodosclientes clientesService = Metodosclientes();
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  void _mostrarFormulario({Map<String, dynamic>? cliente}) {
    final nombreController = TextEditingController(
      text: cliente?['nombre'] ?? '',
    );
    final ciudadController = TextEditingController(
      text: cliente?['ciudad'] ?? '',
    );
    final edadController = TextEditingController(
      text: cliente?['edad']?.toString() ?? '',
    );
    final sexoController = TextEditingController(text: cliente?['sexo'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cliente == null ? "Nuevo Cliente" : "Editar Cliente"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: ciudadController,
                decoration: const InputDecoration(labelText: "Ciudad"),
              ),
              TextField(
                controller: edadController,
                decoration: const InputDecoration(labelText: "Edad"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sexoController,
                decoration: const InputDecoration(labelText: "Sexo"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (cliente == null) {
                await clientesService.insertarCliente(
                  nombre: nombreController.text,
                  ciudad: ciudadController.text,
                  edad: int.tryParse(edadController.text) ?? 0,
                  sexo: sexoController.text,
                );
              } else {
                await clientesService.actualizarCliente(
                  cliente['id'],
                  nombre: nombreController.text,
                  ciudad: ciudadController.text,
                  edad: int.tryParse(edadController.text) ?? 0,
                  sexo: sexoController.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCliente(int id) async {
    await clientesService.eliminarCliente(id);
  }

  Map<String, int> _calculateClientsByCity(List<Map<String, dynamic>> clients) {
    final Map<String, int> cityCounts = {};
    for (var client in clients) {
      final city = client['ciudad'] ?? 'Desconocida';
      cityCounts[city] = (cityCounts[city] ?? 0) + 1;
    }
    return cityCounts;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: clientesService.streamClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay clientes"));
          }

          final clientes = snapshot.data!;
          final filteredClientes = clientes.where((cliente) {
            final nombre = cliente['nombre']?.toLowerCase() ?? '';
            return nombre.contains(_searchTerm.toLowerCase());
          }).toList();

          final clientsByCity = _calculateClientsByCity(clientes);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gestión de Clientes",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: "Buscar cliente...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchTerm = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarFormulario(),
                    icon: const Icon(Icons.add),
                    label: const Text("Nuevo Cliente"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Ciudad')),
                      DataColumn(label: Text('Edad')),
                      DataColumn(label: Text('Sexo')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: filteredClientes.map((cliente) {
                      return DataRow(
                        cells: [
                          DataCell(Text(cliente['id'].toString())),
                          DataCell(Text(cliente['nombre'] ?? '')),
                          DataCell(Text(cliente['ciudad'] ?? '')),
                          DataCell(Text(cliente['edad'].toString())),
                          DataCell(Text(cliente['sexo'] ?? '')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () =>
                                      _mostrarFormulario(cliente: cliente),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _eliminarCliente(cliente['id']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Clientes por Ciudad",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: clientsByCity.entries.map((entry) {
                            final city = entry.key;
                            final count = entry.value;
                            final barHeight = count * 10.0;
                            final color = city == 'Madrid'
                                ? Colors.blue
                                : city == 'Barcelona'
                                ? Colors.teal
                                : Colors.orange;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 20,
                                  height: barHeight,
                                  color: color,
                                ),
                                const SizedBox(height: 4),
                                Text(city),
                                Text(count.toString()),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
