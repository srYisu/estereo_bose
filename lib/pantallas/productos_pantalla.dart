import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/metodosProductos.dart';

class Productos extends StatefulWidget {
  final Supabase supabaseInstancia = Supabase.instance;
  Productos({super.key});

  @override
  State<Productos> createState() => _ProductosState();
}

class _ProductosState extends State<Productos> {
  String nombreProducto = '';
  String categoria = '';
  double precio = 0.0;

  int productoIdSeleccionado = 0;

  Future<void> insertarProducto() async {
    await MetodosProductos.insertarProducto(nombreProducto, categoria, precio);
    setState(() {});
  }

  Future<void> editarProducto() async {
    await MetodosProductos.editarProducto(
      productoIdSeleccionado,
      nombreProducto,
      categoria,
      precio,
    );
    setState(() {});
  }

  Future<void> eliminarProducto() async {
    await MetodosProductos.eliminarProducto(productoIdSeleccionado);
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    return await MetodosProductos.obtenerProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: obtenerProductos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  productoIdSeleccionado == 0) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                final productos = snapshot.data!;
                return DropdownButton<int>(
                  hint: Text('Selecciona un producto'),
                  value: productos.any((p) => p['id'] == productoIdSeleccionado)
                      ? productoIdSeleccionado
                      : null,
                  items: productos.map<DropdownMenuItem<int>>((producto) {
                    return DropdownMenuItem<int>(
                      value: producto['id'] as int,
                      child: Text(producto['nombre'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (int? selectedId) {
                    if (selectedId != null) {
                      final producto = productos.firstWhere(
                        (p) => p['id'] == selectedId,
                      );
                      setState(() {
                        nombreProducto = producto['nombre'] ?? '';
                        productoIdSeleccionado = selectedId;
                        print(productoIdSeleccionado);
                      });
                    }
                  },
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
          TextField(
            decoration: InputDecoration(hintText: 'Nombre del Producto'),
            onChanged: (value) {
              nombreProducto = value;
            },
          ),
          TextField(
            decoration: InputDecoration(hintText: 'Categoria'),
            onChanged: (value) {
              categoria = value;
            },
          ),
          TextField(
            decoration: InputDecoration(hintText: 'Precio'),
            onChanged: (value) {
              precio = double.tryParse(value) ?? 0.0;
            },
          ),

          // Acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: insertarProducto,
                child: Text('Guardar'),
              ),
              ElevatedButton(
                onPressed: editarProducto,
                child: Text('Actualizar'),
              ),
              ElevatedButton(
                onPressed: eliminarProducto,
                child: Text('Eliminar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
