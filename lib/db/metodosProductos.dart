import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosProductos {
  static Future<void> insertarProducto(
    String nombre,
    String categoria,
    double precio,
  ) async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('productos').insert({
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
    });
    print(response);
  }

  static Future<void> editarProducto(
    int id,
    String nombre,
    String categoria,
    double precio,
  ) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('productos')
        .update({'nombre': nombre, 'categoria': categoria, 'precio': precio})
        .eq('id', id);
    print(response);
  }

  static Future<void> eliminarProducto(int id) async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('productos').delete().eq('id', id);
    print(response);
  }

  static Future<List<Map<String, dynamic>>> obtenerProductos() async {
    final supabase = Supabase.instance.client;
    final productos = await supabase.from('productos').select('id, nombre');
    return productos;
  }
}
