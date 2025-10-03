import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Productos extends StatefulWidget {
  final Supabase supabaseInstancia = Supabase.instance;
  Productos({super.key,});

  @override
  State<Productos> createState() => _ProductosState();
}

class _ProductosState extends State<Productos> {
  String nombreProducto = '';
  String categoria = '';
  double precio = 0.0;

  int productoIdSeleccionado = 0;

  Future<void> insertarProducto() async {
    final supabase = Supabase.instance.client; //
    final response = await supabase.from('productos').insert({
      'nombre': nombreProducto,
      'categoria': categoria,
      'precio': precio,
    });
    setState(() {
      
    });
    print(response);
  }
  Future<void> editarProducto() async {
    final supabase = Supabase.instance.client; 
    final response = await supabase.from('productos')
      .update({'nombre': nombreProducto, 'categoria': categoria, 'precio': precio})
      .eq('id', productoIdSeleccionado);
    setState(() {

    });
    print(response);
  }
  Future<void> eliminarProducto() async {
    final supabase = Supabase.instance.client; 
    final response = await supabase.from('productos')
      .delete()
      .eq('id', productoIdSeleccionado);
    setState(() {

    });
    print(response);
  }

Future<Widget> obtenerProductos() async {
  final supabase = Supabase.instance.client;
  final productos = await supabase
      .from('productos')
      .select('id, nombre');

  return DropdownButton<int>(
    hint: Text('Selecciona un producto'),
    value: productos.any((p) => p['id'] == productoIdSeleccionado) ? productoIdSeleccionado : null,
    items: productos.map<DropdownMenuItem<int>>((producto) {
      return DropdownMenuItem<int>(
        value: producto['id'] as int,
        child: Text(producto['nombre'] ?? ''),
      );
    }).toList(),
    onChanged: (int? selectedId) {
      if (selectedId != null) {
        final producto = productos.firstWhere((p) => p['id'] == selectedId);
        setState(() {
          nombreProducto = producto['nombre'] ?? '';
          productoIdSeleccionado = selectedId;
          print(productoIdSeleccionado);
        });
      }
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FutureBuilder<Widget>(
              future: obtenerProductos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && productoIdSeleccionado == 0) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  return snapshot.data!;
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Nombre del Producto',               
              ),
              onChanged: (value) {
                nombreProducto = value;
              }
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Categoria',               
              ),
              onChanged: (value) {
                categoria = value;
              }
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Nombre del Producto',               
              ),
              onChanged: (value) {
                precio = double.tryParse(value) ?? 0.0;
              }
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
                  child: Text('Elimianr'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}