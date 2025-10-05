import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/metodosVentas.dart';
import '../db/metodosClientes.dart';
import '../db/metodosProductos.dart';
import '../db/metodosDetallesVentas.dart';
import 'estadisticas_pantalla.dart';
import 'package:supabase/supabase.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final supabase = Supabase.instance.client;
  int cantidadVentasHoy = 0;
  final MetodosVentas ventasService = MetodosVentas();
  final Metodosclientes clientesService = Metodosclientes();
  final MetodosProductos productosService = MetodosProductos();
  final MetodosDetallesVentas detallesVentaService = MetodosDetallesVentas();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  String _searchTerm = '';
  int? _selectedIdCliente; // store selected cliente across dialog
  int? _selectedIdProducto; // store selected producto across dialog
  int? _selectedIdDetallesVenta; // store selected producto across dialog
  // ahora guarda mapas con {'id': <int>, 'cantidad': <int>, 'id_detalle': <int?>}
  List<Map<String, int?>> _productosAgregados = [];
  //List<ProductosAgregados> _productosAgregados = [];

  int _currentPage = 0; // Current page index for pagination
  Future<void> cargarEstadisticas() async {
    try {
      final cantidad = await supabase.rpc('cantidad_ventas_mes');
      cantidadVentasHoy = (cantidad as num?)?.toInt() ?? 0;

    } catch (e) {
      // Manejar errores si es necesario
      debugPrint('Error al cargar estadísticas: $e');
    } 
  }
  @override
  void initState() {
    super.initState();
    _productosAgregados = [];
    cargarEstadisticas();
  }
  

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
          return DropdownMenuItem<int>(
            value: id,
            child: Text('$nombre'),
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

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
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
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    if (_selectedIdProducto == null) return;
                    final qty = int.tryParse(_cantidadController.text) ?? 1;

                    // obtener el producto para comprobar stock
                    final producto = await productosService.obtenerProductoPorId(_selectedIdProducto!);
                    final stock = (producto?['cantidad'] as int?) ?? 0;

                    // si la cantidad es mayor al stock no permitir la compra
                    final idx = _productosAgregados.indexWhere((e) => e['id'] == _selectedIdProducto);
                    final currentQty = idx >= 0 ? (_productosAgregados[idx]['cantidad'] ?? 0) : 0;
                    if (qty > stock) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Stock insuficiente'),
                          content: Text('No se puede agregar $qty unidades. Stock disponible: $stock.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Aceptar'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    setState(() {
                      if (idx >= 0) {
                        _productosAgregados[idx]['cantidad'] = qty; /*+ (_productosAgregados[idx]['cantidad'] ?? 0);*/
                      } else {
                        _productosAgregados.add({'id': _selectedIdProducto!, 'cantidad': qty});
                      }
                      _cantidadController.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                hintText: 'Ingresa cantidad antes de añadir',
              ),
            )
          ],
        );
      },
    );
  }

  void _verProductosComprados(int id) async {
    final detalles = await detallesVentaService.obtenerDetallesVentasPorVentaId(id);
    if (detalles == null || detalles.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Productos Comprados'),
          content: const Text('No se encontraron productos para esta venta.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    // Obtener los nombres de los productos relacionados
    List<String> nombresProductos = [];
    for (var detalle in detalles) {
      final idProducto = detalle['id_producto'];
      final producto = await productosService.obtenerProductoPorId(idProducto);
      if (producto != null) {
        nombresProductos.add("${producto['nombre']}   €${producto['precio']} C/u");
      }
    }

    // Mostrar el diálogo con la lista vertical de nombres de productos
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Productos Comprados'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: nombresProductos.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(nombresProductos[index]),
                subtitle: Text("Cantidad: ${detalles[index]['cantidad']}"),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarFormulario({Map<String, dynamic>? venta}) async {
    int nextVentaId = 1;
    try {
      final resp = await Supabase.instance.client
          .from('ventas')
          .select('id')
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();
      if (resp != null && resp['id'] != null) {
        final lastId = (resp['id'] as num?)?.toInt() ?? 0;
        nextVentaId = lastId + 1;
      }
    } catch (_) {
      nextVentaId = 1;
    }

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
              const SizedBox(height: 8),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: selectedFecha != null
                      ? selectedFecha!.toIso8601String().substring(0, 10)
                      : 'Fecha',
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
              const SizedBox(height: 16),
              // mostrar suma de cantidades
              Text(
                'Productos Agregados: x${_productosAgregados.fold<int>(0, (prev, e) => prev + (e['cantidad'] ?? 0))}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _verAgregarProductos(), 
                child: const Text('Agregar Productos')
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _selectedIdCliente = null;
              _selectedIdProducto = null;
              _productosAgregados = [];
              Navigator.pop(context);
            },
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Calcular total y preparar inserciones de detalles
              double total = 0;
              for (var entry in _productosAgregados) {
                final int? pid = entry['id'];
                final int qty = entry['cantidad'] ?? 0;
                if (pid == null || qty <= 0) continue;
                final producto = await productosService.obtenerProductoPorId(pid);
                double precio = 0.0;
                if (producto != null) {
                  final p = producto['precio'];
                  if (p is num) {
                    precio = p.toDouble();
                  } else {
                    precio = double.tryParse(p?.toString() ?? '') ?? 0.0;
                  }
                }
                total += precio * qty;
              }

              if (venta == null) {
                // Insertar la venta y detalles
                await ventasService.insertarVentas(
                  id_cliente: _selectedIdCliente ?? selectedIdCliente ?? 0,
                  total: total,
                  fecha: selectedFecha ?? DateTime.now(),
                );

                for (var entry in _productosAgregados) {
                  final int? pid = entry['id'];
                  final int qty = entry['cantidad'] ?? 0;
                  if (pid == null || qty <= 0) continue;

                  await detallesVentaService.insertarDetallesVentas(
                    id_producto: pid,
                    id_venta: nextVentaId,
                    cantidad: qty,                    
                  );
                }
              } else {
                await ventasService.actualizarVentas(
                  venta['id'],
                  id_cliente: _selectedIdCliente ?? selectedIdCliente ?? 0,
                  fecha: selectedFecha ?? DateTime.now(),
                  total: total,
                );
                
                // actualizar venta y detalles
                for (var entry in _productosAgregados) {
                  final int? pid = entry['id'];
                  final int qty = entry['cantidad'] ?? 0;
                  if (pid == null || qty <= 0) continue;
                  final int? detId = entry['id_detalle'];
                  if (detId != null) {
                    await detallesVentaService.actualizarDetallesVentas(
                      detId,
                      id_producto: pid,
                      id_venta: venta['id'],
                      cantidad: qty,
                    );
                  } else {
                    await detallesVentaService.insertarDetallesVentas(
                      id_producto: pid,
                      id_venta: venta['id'],
                      cantidad: qty,
                    );
                  }
                }
              }
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

  void _verAgregarProductos() async
  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Productos'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    listaProductos(),
                    const SizedBox(height: 16),
                      if(_productosAgregados.isEmpty == false)...[
                       
                      SizedBox(
                        height: 200,
                        width: 300,
                        child: ListView.builder(
                          itemCount: _productosAgregados.length,
                          itemBuilder: (context, index) {
                             final entry = _productosAgregados[index];
                             final int? id = entry['id'];
                             final cantidad = entry['cantidad'] ?? 0;
                             return FutureBuilder<Map<String, dynamic>?>(
                               future: productosService.obtenerProductoPorId(id!),
                               builder: (context, snapshot) {
                                 if (snapshot.connectionState == ConnectionState.waiting) {
                                   return const ListTile(title: Text('Cargando...'));
                                 }
                                 final producto = snapshot.data;
                                 final nombre = producto?['nombre'] ?? 'Desconocido';
                                 return ListTile(
                                   title: Text('$nombre'),
                                   subtitle: Text('Cantidad: $cantidad'),
                                   trailing: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       IconButton(
                                         icon: const Icon(Icons.remove),
                                         onPressed: () {
                                           setState(() {
                                             if (cantidad > 1) {
                                              //_productosAgregados[index]['cantidad'] = cantidad - 1;
                                              _productosAgregados[index]['cantidad'] = 0; // Muy lageado como para restar uno
                                               _productosAgregados.removeAt(index);
                                             } else {
                                               _productosAgregados.removeAt(index);
                                             }
                                           });
                                         },
                                       ),
                                     ],
                                   ),
                                 );
                               },
                             );
                          },
                        ),
                      ),
                     ]
                     else... [
                       const Text('No hay productos agregados'),
                     ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _eliminarVenta(int id) async {
    await ventasService.eliminarVentas(id);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Ventas'),
      ),
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
                      hintText: "Buscar por ID Cliente o por Fecha...",
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
                    final fecha = (venta['fecha'] as String).length >= 10
                        ? (venta['fecha'] as String).substring(0, 10)
                        : (venta['fecha'] as String);
                    return idCliente.contains(_searchTerm) || fecha.contains(_searchTerm);
                  }).toList();

                  final salesByProduct = _calculateSalesByProduct(ventas);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const double rowHeight = 56.0;
                            const double headerHeight = 56.0;
                            final availableHeight = constraints.maxHeight - headerHeight - 40;
                            final rowsPerPage = availableHeight ~/ rowHeight;

                            final totalPages = (filteredVentas.length / rowsPerPage).ceil();
                            if (_currentPage > 0 && _currentPage >= totalPages) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  _currentPage = 0;
                                });
                              });
                            }

                            final startIndex = _currentPage * rowsPerPage;
                            final endIndex = (startIndex + rowsPerPage) > filteredVentas.length
                                ? filteredVentas.length
                                : (startIndex + rowsPerPage);
                            final pageItems = filteredVentas.sublist(startIndex, endIndex);

                            final dataRows = pageItems.asMap().entries.map((entry) {
                              int index = entry.key;
                              var venta = entry.value;
                              return DataRow(
                                color: index % 2 == 0
                                    ? MaterialStateProperty.all(Colors.grey[200])
                                    : MaterialStateProperty.all(Colors.white),
                                cells: [
                                  DataCell(Text(venta['id'].toString())),
                                  DataCell(Text(venta['id_cliente'].toString())),
                                  DataCell(Text("€ ${venta['Total'].toString()}")),
                                  DataCell(Text(
                                    (venta['fecha'] as String).length >= 10
                                        ? (venta['fecha'] as String).substring(0, 10)
                                        : (venta['fecha'] as String),
                                  )),
                                  DataCell(
                                    Row(
                                      children: [
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
                                                await _eliminarVenta(venta['id']);
                                              }
                                            },
                                        ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _verProductosComprados(venta['id']), 
                                          child: const Text('Ver Productos'),
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
                                          headingRowColor: MaterialStateProperty.all(
                                            Colors.grey[900],
                                          ),
                                          headingTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          columns: const [
                                            DataColumn(label: Text('ID')),
                                            DataColumn(label: Text('ID Cliente')),
                                            DataColumn(label: Text('Monto Total')),
                                            DataColumn(label: Text('Fecha')),
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
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    _compactDashboardCard(
      color: const Color.fromARGB(255, 13, 126, 116),
      title: "VENTAS HOY",
      value: cantidadVentasHoy.toStringAsFixed(0),
      subtitle: "YEEEPIEEEE",
    ),
  ],
),
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
  Widget _compactDashboardCard({
    required Color color,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
}

