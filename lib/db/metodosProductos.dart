import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosProductos {
  final supabase = Supabase.instance.client;

  Future<void> insertarProducto({
    required String nombre,
    required String categoria,
    required double precio,
    required int cantidad,
  }) async {
    await supabase.from('productos').insert({
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
      'cantidad': cantidad,
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
    required int cantidad,
  }) async {
    await supabase
        .from('productos')
        .update({'nombre': nombre, 'categoria': categoria, 'precio': precio, 'cantidad': cantidad})
        .eq('id', id);
  }

  Future<void> cambiarStock(
    int id, {
    required int cantidad,
  }) async {
    await supabase
        .from('productos')
        .update({'cantidad': cantidad})
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

  Future<Map<String, dynamic>?> obtenerProductoPorId(int id) async {
    final response = await supabase.from('productos').select().eq('id', id).single();
    return response as Map<String, dynamic>?;
  }
}
