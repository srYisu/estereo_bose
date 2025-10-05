import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/metodosProductos.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final MetodosProductos productosService = MetodosProductos();
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  int _currentPage = 0; // Current page index for pagination

  void _mostrarFormulario({Map<String, dynamic>? producto}) {
    
    final nombreController = TextEditingController(
      text: producto?['nombre'] ?? '',
    );
    final categoriaController = TextEditingController(
      text: producto?['categoria'] ?? '',
    );
    final precioController = TextEditingController(
      text: producto?['precio']?.toString() ?? '',
    );
    final cantidadController = TextEditingController(
      text: producto?['cantidad']?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(producto == null ? "Nuevo Producto" : "Editar Producto"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(labelText: "Categoria"),
              ),
              TextField(
                controller: precioController,
                decoration: const InputDecoration(labelText: "Precio"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(labelText: "Cantidad"),
                keyboardType: TextInputType.numberWithOptions(signed: false),
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
              if (producto == null) {
                await productosService.insertarProducto(
                  nombre: nombreController.text,
                  categoria: categoriaController.text,
                  precio: double.tryParse(precioController.text) ?? 0.0,
                  cantidad: int.tryParse(cantidadController.text) ?? 0,
                );
              } else {
                await productosService.actualizarProducto(
                  producto['id'],
                  nombre: nombreController.text,
                  categoria: categoriaController.text,
                  precio: double.tryParse(precioController.text) ?? 0.0,
                  cantidad: int.tryParse(cantidadController.text) ?? 0,
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

  Future<void> _eliminarProducto(int id) async {
    await productosService.eliminarProducto(id);
  }

  Map<String, int> _calculateProductsByCategory(
    List<Map<String, dynamic>> products,
  ) {
    final Map<String, int> categoryCounts = {};
    for (var product in products) {
      final category = product['categoria'] ?? 'Desconocida';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    return categoryCounts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Productos')),
      body: Padding(
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
                      hintText: "Buscar producto...",
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
                  label: const Text("Nuevo Producto"),
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: productosService.streamProductos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No hay productos disponibles"),
                    );
                  }

                  final productos = snapshot.data!;
                  final filteredProductos = productos.where((producto) {
                    final nombre = producto['nombre']?.toLowerCase() ?? '';
                    final categoria =
                        producto['categoria']?.toLowerCase() ?? '';
                    final searchLower = _searchTerm.toLowerCase();
                    return nombre.contains(searchLower) ||
                        categoria.contains(searchLower);
                  }).toList();
                  final productsByCategory = _calculateProductsByCategory(
                    filteredProductos,
                  );

                  return Column(
                    children: [
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
                                (filteredProductos.length / rowsPerPage).ceil();
                            if (_currentPage > 0 && _currentPage >= totalPages) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  _currentPage = 0;
                                });
                              });
                            }

                            final startIndex = _currentPage * rowsPerPage;
                            final endIndex =
                                (startIndex + rowsPerPage) > filteredProductos.length
                                ? filteredProductos.length
                                : (startIndex + rowsPerPage);
                            final pageItems = filteredProductos.sublist(
                              startIndex,
                              endIndex,
                            );

                            // Genera las filas de la tabla
                            final dataRows = pageItems.asMap().entries.map((entry) {
                              int index = entry.key;
                              var producto = entry.value;
                              return DataRow(
                                color: index % 2 == 0
                                    ? MaterialStateProperty.all(Colors.grey[200])
                                    : MaterialStateProperty.all(Colors.white),
                                cells: [
                                  DataCell(Text(producto['id'].toString())),
                                  DataCell(Text(producto['nombre'] ?? '')),
                                  DataCell(Text(producto['categoria'] ?? '')),
                                  DataCell(Text(producto['precio'].toString())),
                                  DataCell(Text(producto['cantidad'].toString())),
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
                                            onPressed: () =>
                                                _mostrarFormulario(producto: producto),
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
                                                    "¿Estás seguro de que deseas eliminar este producto?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(context, false),
                                                      child: const Text("Cancelar"),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(context, true),
                                                      child: const Text("Eliminar"),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await _eliminarProducto(producto['id']);
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
                                            DataColumn(label: Text('Categoría')),
                                            DataColumn(label: Text('Precio')),
                                            DataColumn(label: Text('Cantidad')),
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
                      
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
