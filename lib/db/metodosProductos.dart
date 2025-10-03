import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosProductos {
  final supabase = Supabase.instance.client;

  Future<void> insertarProducto({
    required String nombre,
    required String categoria,
    required double precio,
  }) async {
    await supabase.from('productos').insert({
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
    });
  }

  Future<void> eliminarProducto(int id) async {
    await supabase.from('productos').delete().eq('id', id);
  }

  Future<void> actualizarProducto(
    int id, {
    required String nombre,
    required String categoria,
    required double precio,
  }) async {
    await supabase
        .from('productos')
        .update({'nombre': nombre, 'categoria': categoria, 'precio': precio})
        .eq('id', id);
  }

  Stream<List<Map<String, dynamic>>> streamProductos() {
    return supabase
        .from('productos')
        .stream(primaryKey: ['id'])
        .order('id')
        .execute()
        .map((rows) => rows.map((r) => r as Map<String, dynamic>).toList());
  }
}
