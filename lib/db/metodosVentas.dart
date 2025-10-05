import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosVentas {
  final supabase = Supabase.instance.client;

  Future<void> insertarVentas({
    required int id_cliente,
    required DateTime fecha,
    required double total,
  }) async {
    await supabase.from('ventas').insert({
      'id_cliente': id_cliente,
      'fecha': fecha.toIso8601String(),
      'Total': total,
    });
  }

  Future<void> eliminarVentas(int id) async {
    await supabase.from('ventas').delete().eq('id', id);
  }

  Future<void> actualizarVentas(
    int id, {
    required int id_cliente,
    required DateTime fecha,
    required double total,
  }) async {
    await supabase
        .from('ventas')
        .update({'id_cliente': id_cliente, 'fecha': fecha.toIso8601String(), 'Total': total})
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
