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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gestión de Productos",
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
                      return const Center(child: Text("No hay productos disponibles"));
                    }

                    final productos = snapshot.data!;
                    final filteredProductos = productos.where((producto) {
                      final nombre = producto['nombre']?.toLowerCase() ?? '';
                      final categoria = producto['categoria']?.toLowerCase() ?? '';
                      final searchLower = _searchTerm.toLowerCase();
                      return nombre.contains(searchLower) ||
                          categoria.contains(searchLower);
                    }).toList();
                    final productsByCategory = _calculateProductsByCategory(filteredProductos);

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Categoria')),
                      DataColumn(label: Text('Precio')),
                      DataColumn(label: Text('Cantidad')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: filteredProductos.map((producto) {
                      return DataRow(
                        cells: [
                          DataCell(Text(producto['id'].toString())),
                          DataCell(Text(producto['nombre'] ?? '')),
                          DataCell(Text(producto['categoria'] ?? '')),
                          DataCell(Text(producto['precio'].toString())),
                          DataCell(Text(producto['cantidad'].toString())),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () =>
                                      _mostrarFormulario(producto: producto),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _eliminarProducto(producto['id']),
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
                        "Productos por Categoria",
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
                          children: productsByCategory.entries.map((entry) {
                            final category = entry.key;
                            final count = entry.value;
                            final barHeight = count * 10.0;
                            final color = category == 'Electrónica'
                                ? Colors.blue
                                : category == 'Ropa'
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
                                Text(category),
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
          ),
        ],
      ),      
    );
  }
}
