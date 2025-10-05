import 'package:flutter/material.dart';
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

  int _currentPage = 0; // Current page index for pagination
  static const int _rowsPerPage = 10; // Number of rows per page

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
    await clientesService.eliminarClienteConVerificacion(id);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Clientes')),
      body: Padding(
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

            final clientes = snapshot.data!
                .where((c) => c['activo'] == true)
                .toList();

            final filteredClientes = clientes.where((cliente) {
              final nombre = cliente['nombre']?.toLowerCase() ?? '';
              return nombre.contains(_searchTerm.toLowerCase());
            }).toList();

            final clientsByCity = _calculateClientsByCity(clientes);

            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Altura aproximada de cada fila (ajusta según tu diseño)
                        const double rowHeight = 56.0;
                        // Altura de encabezado de la tabla
                        const double headerHeight = 56.0;
                        // Calcula cuántas filas caben
                        final availableHeight =
                            constraints.maxHeight - headerHeight - 40;
                        final rowsPerPage = availableHeight ~/ rowHeight;

                        // Si cambia el tamaño y la página actual ya no existe, vuelve a la página 1
                        final totalPages =
                            (filteredClientes.length / rowsPerPage).ceil();
                        if (_currentPage > 0 && _currentPage >= totalPages) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _currentPage = 0;
                            });
                          });
                        }

                        final startIndex = _currentPage * rowsPerPage;
                        final endIndex =
                            (startIndex + rowsPerPage) > filteredClientes.length
                            ? filteredClientes.length
                            : (startIndex + rowsPerPage);
                        final pageItems = filteredClientes.sublist(
                          startIndex,
                          endIndex,
                        );

                        // Genera las filas de la tabla
                        final dataRows = pageItems.asMap().entries.map((entry) {
                          int index = entry.key;
                          var cliente = entry.value;
                          return DataRow(
                            color: index % 2 == 0
                                ? MaterialStateProperty.all(Colors.grey[200])
                                : MaterialStateProperty.all(Colors.white),
                            cells: [
                              DataCell(Text(cliente['id'].toString())),
                              DataCell(Text(cliente['nombre'] ?? '')),
                              DataCell(Text(cliente['ciudad'] ?? '')),
                              DataCell(Text(cliente['edad'].toString())),
                              DataCell(Text(cliente['sexo'] ?? '')),
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                        ),
                                        onPressed: () => _mostrarFormulario(
                                          cliente: cliente,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                "Confirmar Eliminación",
                                              ),
                                              content: const Text(
                                                "¿Estás seguro de que deseas eliminar este cliente?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text("Cancelar"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text("Eliminar"),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await _eliminarCliente(
                                              cliente['id'],
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList();

                        // Añade filas vacías si faltan para llenar la página
                        for (int i = dataRows.length; i < rowsPerPage; i++) {
                          dataRows.add(
                            DataRow(
                              color: i % 2 == 0
                                  ? MaterialStateProperty.all(Colors.grey[200])
                                  : MaterialStateProperty.all(Colors.white),
                              cells: const [
                                DataCell(Text('')),
                                DataCell(Text('')),
                                DataCell(Text('')),
                                DataCell(Text('')),
                                DataCell(Text('')),
                                DataCell(Text('')),
                              ],
                            ),
                          );
                        }

                        return Center(
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(0),
                              width: 800,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                            Colors.grey[900],
                                          ),
                                      headingTextStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('ID')),
                                        DataColumn(label: Text('Nombre')),
                                        DataColumn(label: Text('Ciudad')),
                                        DataColumn(label: Text('Edad')),
                                        DataColumn(label: Text('Sexo')),
                                        DataColumn(label: Text('Acciones')),
                                      ],
                                      rows: dataRows,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new,
                                        ),
                                        onPressed: _currentPage > 0
                                            ? () {
                                                setState(() {
                                                  _currentPage--;
                                                });
                                              }
                                            : null,
                                      ),
                                      for (int i = 0; i < totalPages; i++)
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _currentPage = i;
                                            });
                                          },
                                          child: Text(
                                            (i + 1).toString(),
                                            style: TextStyle(
                                              fontWeight: i == _currentPage
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: i == _currentPage
                                                  ? Colors.blue
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_forward_ios,
                                        ),
                                        onPressed: _currentPage < totalPages - 1
                                            ? () {
                                                setState(() {
                                                  _currentPage++;
                                                });
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 300, minWidth: 200),
                      child: Container(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
