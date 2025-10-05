import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosDetallesVentas {
  final supabase = Supabase.instance.client;

  Future<void> insertarDetallesVentas({
    required int id_producto,
    required int id_venta,
    required int cantidad,
  }) async {
    await supabase.from('detallesVentas').insert({
      'id_producto': id_producto,
      'id_venta': id_venta,
      'cantidad': cantidad,
    });
  }

  Future<void> eliminarDetallesVentas(int id) async {
    await supabase.from('detallesVentas').delete().eq('id', id);
  }

  Future<void> actualizarDetallesVentas(
    int id, {
    required int id_producto,
    required int id_venta,
    required int cantidad,
  }) async {
    await supabase
        .from('detallesVentas')
        .update({'id_cliente': id_producto, 'id_venta': id_venta, 'cantidad': cantidad})
        .eq('id', id);
  }

  Stream<List<Map<String, dynamic>>> streamDetallesVentas() {
    return supabase
        .from('DetallesVentas')
        .stream(primaryKey: ['id'])
        .order('id')
        .execute()
        .map((rows) => rows.map((r) => r as Map<String, dynamic>).toList());
  }

  Future<List<Map<String, dynamic>>> obtenerDetallesVentasPorVentaId(int idVenta) async {
    final response = await supabase.from('detallesVentas').select().eq('id_venta', idVenta);
    return response as List<Map<String, dynamic>>;
  }
}

class ProductosAgregados {
  final int id;
  final int cantidad;

  ProductosAgregados({required this.id, required this.cantidad});
}