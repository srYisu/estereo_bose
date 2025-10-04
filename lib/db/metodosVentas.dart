import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosVentas {
  final supabase = Supabase.instance.client;

  Future<void> insertarVentas({
    required int id_cliente,
    required int id_producto,
    required int cantidad,
    required DateTime fecha,
  }) async {
    await supabase.from('ventas').insert({
      'id_cliente': id_cliente,
      'id_producto': id_producto,
      'cantidad': cantidad,
      'fecha': fecha.toIso8601String(),
    });
  }

  Future<void> elimiarVentas(int id) async {
    await supabase.from('ventas').delete().eq('id', id);
  }

  Future<void> actualizarVentas(
    int id, {
    required int id_cliente,
    required int id_producto,
    required int cantidad,
    required DateTime fecha,
  }) async {
    await supabase
        .from('ventas')
        .update({'id_cliente': id_cliente, 'id_producto': id_producto, 'cantidad': cantidad, 'fecha': fecha.toIso8601String()})
        .eq('id', id);
  }

  Stream<List<Map<String, dynamic>>> streamVentas() {
    return supabase
        .from('ventas')
        .stream(primaryKey: ['id'])
        .order('id')
        .execute()
        .map((rows) => rows.map((r) => r as Map<String, dynamic>).toList());
  }
}
