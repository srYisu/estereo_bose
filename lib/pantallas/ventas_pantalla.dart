import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/metodosVentas.dart';
import '../db/metodosClientes.dart';
import '../db/metodosProductos.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final MetodosVentas ventasService = MetodosVentas();
  final Metodosclientes clientesService = Metodosclientes();
  final MetodosProductos productosService = MetodosProductos();
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  int? _selectedIdCliente; // store selected cliente across dialog
  int? _selectedIdProducto; // store selected producto across dialog

  Widget listaClientes() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: clientesService.streamClientes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No hay clientes disponibles');
        }
        final clientes = snapshot.data!;

        // Build list of DropdownMenuItem with id as value and full name as child
        final items = clientes.map((cliente) {
          final id = cliente['id'] as int?;
          final nombre = cliente['nombre'] ?? '';
          final apellido = cliente['apellido'] ?? '';
          return DropdownMenuItem<int>(
            value: id,
            child: Text('$nombre $apellido'),
          );
        }).toList();

        return DropdownButtonFormField<int>(
          value: _selectedIdCliente,
          decoration: const InputDecoration(
            labelText: 'Seleccionar Cliente',
          ),
          items: items,
          onChanged: (value) {
            setState(() {
              _selectedIdCliente = value;
            });
          },
          validator: (v) => v == null ? 'Seleccione un cliente' : null,
        );
      },
    );
  }

  Widget listaProductos() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: productosService.streamProductos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No hay productos disponibles');
        }
        final productos = snapshot.data!;

        // Build list of DropdownMenuItem with id as value and product name as child
        final items = productos.map((producto) {
          final id = producto['id'] as int?;
          final nombre = producto['nombre'] ?? '';
          return DropdownMenuItem<int>(
            value: id,
            child: Text(nombre),
          );
        }).toList();

        return DropdownButtonFormField<int>(
          value: _selectedIdProducto,
          decoration: const InputDecoration(
            labelText: 'Seleccionar Producto',
          ),
          items: items,
          onChanged: (value) {
            setState(() {
              _selectedIdProducto = value;
            });
          },
          validator: (v) => v == null ? 'Seleccione un producto' : null,
        );
      },
    );
  }
  void _mostrarFormulario({Map<String, dynamic>? venta}) {
    int? selectedIdCliente = venta?['id_cliente'] ?? _selectedIdCliente;
    int? selectedIdProducto = venta?['id_producto'] ?? _selectedIdProducto;
    final cantidadController = TextEditingController(
      text: venta?['cantidad']?.toString() ?? '',
    );
    DateTime? selectedFecha = venta != null ? DateTime.parse(venta['fecha']) : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(venta == null ? "Nueva Venta" : "Editar Venta"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Seleccionar Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              listaClientes(),
              const SizedBox(height: 16),
              const Text('Seleccionar Producto:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              listaProductos(),
              const SizedBox(height: 16),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(labelText: "Cantidad"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Fecha",
                  hintText: selectedFecha != null
                      ? selectedFecha!.toIso8601String().substring(0, 10)
                      : 'Seleccionar fecha',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedFecha ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != selectedFecha) {
                    setState(() {
                      selectedFecha = picked;
                    });
                  }
                },
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
              if (venta == null) {
                await ventasService.insertarVentas(
                  id_cliente: _selectedIdCliente ?? selectedIdCliente ?? 0,
                  id_producto: _selectedIdProducto ?? selectedIdProducto ?? 0,
                  cantidad: int.tryParse(cantidadController.text) ?? 0,
                  fecha: selectedFecha ?? DateTime.now(),
                );
              } else {
                await ventasService.actualizarVentas(
                  venta['id'],
                  id_cliente: _selectedIdCliente ?? selectedIdCliente ?? 0,
                  id_producto: _selectedIdProducto ?? selectedIdProducto ?? 0,
                  cantidad: int.tryParse(cantidadController.text) ?? 0,
                  fecha: selectedFecha ?? DateTime.now(),
                );
              }
              // keep the selected id in state for next time
              setState(() {
                _selectedIdCliente = _selectedIdCliente ?? selectedIdCliente;
                _selectedIdProducto = _selectedIdProducto ?? selectedIdProducto;
              });
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarVenta(int id) async {
    await ventasService.elimiarVentas(id);
  }

  Map<int, int> _calculateSalesByProduct(List<Map<String, dynamic>> ventas) {
    final Map<int, int> productCounts = {};
    for (var venta in ventas) {
      final idProducto = (venta['id_producto'] as int?) ?? 0;
      productCounts[idProducto] = (productCounts[idProducto] ?? 0) + ((venta['cantidad'] as int?) ?? 0);
    }
    return productCounts;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gestión de Ventas",
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
                    hintText: "Buscar por ID Cliente o ID Producto...",
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
                label: const Text("Nueva Venta"),
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
              stream: ventasService.streamVentas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No hay ventas"));
                }

                final ventas = snapshot.data!;
                final filteredVentas = ventas.where((venta) {
                  final idCliente = venta['id_cliente']?.toString() ?? '';
                  final idProducto = venta['id_producto']?.toString() ?? '';
                  return idCliente.contains(_searchTerm) || idProducto.contains(_searchTerm);
                }).toList();

                final salesByProduct = _calculateSalesByProduct(ventas);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('ID Cliente')),
                            DataColumn(label: Text('ID Producto')),
                            DataColumn(label: Text('Cantidad')),
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: filteredVentas.map((venta) {
                            return DataRow(
                              cells: [
                                DataCell(Text(venta['id'].toString())),
                                DataCell(Text(venta['id_cliente'].toString())),
                                DataCell(Text(venta['id_producto'].toString())),
                                DataCell(Text(venta['cantidad'].toString())),
                                DataCell(Text(
                                  (venta['fecha'] as String).length >= 10
                                      ? (venta['fecha'] as String).substring(0, 10)
                                      : (venta['fecha'] as String),
                                )),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                        ),
                                        onPressed: () => _mostrarFormulario(venta: venta),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _eliminarVenta(venta['id']),
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
                              "Cantidad Vendida por Producto",
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
                                children: salesByProduct.entries.map((entry) {
                                  final idProducto = entry.key;
                                  final cantidad = entry.value;
                                  final barHeight = cantidad * 5.0; // Adjust scale
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: barHeight,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Prod $idProducto'),
                                      Text(cantidad.toString()),
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
