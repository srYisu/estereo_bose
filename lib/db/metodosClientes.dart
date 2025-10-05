import 'package:supabase_flutter/supabase_flutter.dart';

class Metodosclientes {
  final supabase = Supabase.instance.client;

  Future<void> insertarCliente({
    required String nombre,
    required String ciudad,
    required int edad,
    required String sexo,
  }) async {
    await supabase.from('clientes').insert({
      'nombre': nombre,
      'ciudad': ciudad,
      'edad': edad,
      'sexo': sexo,
    });
  }

  /*
  Future<void> eliminarCliente(int id) async {
    await supabase.from('clientes').delete().eq('id', id);
  }

  Future<void> eliminarClientes_TrueFalse(int id) async{
    await supabase.from('clientes').update({'activo': false}).eq('id', id);
  }
  */
  Future<void> eliminarClienteConVerificacion(int id) async {
  final ventas = await supabase
      .from('ventas')
      .select('id')
      .eq('id_cliente', id);
  if (ventas.isEmpty) {
    await supabase.from('clientes').delete().eq('id', id);
  } 
  else {
    await supabase.from('clientes').update({'activo': false}).eq('id', id);
  }
}



  Future<void> actualizarCliente(
    int id, {
    required String nombre,
    required String ciudad,
    required int edad,
    required String sexo,
  }) async {
    await supabase.from('clientes').update({
      'nombre': nombre,
      'ciudad': ciudad,
      'edad': edad,
      'sexo': sexo,
    }).eq('id', id);
  }
//
  Stream<List<Map<String, dynamic>>> streamClientes() {
    return supabase
        .from('clientes')
        .stream(primaryKey: ['id'])
        .order('id')
        .map((rows) => rows.map((r) => r as Map<String, dynamic>).toList());
  }
}