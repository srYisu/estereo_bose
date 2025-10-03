import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:estereo_bose/db/metodosClientes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fzvfhnekmculrrnbsdqu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6dmZobmVrbWN1bHJybmJzZHF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkzODA2NzQsImV4cCI6MjA3NDk1NjY3NH0.lWVwSZIHnVuzYjTIj-r1IlwnvvlsHGxwm3gPZUA7puM'
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clientes App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ClientesPage(),
    );
  }
}

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final Metodosclientes clientesService = Metodosclientes();

  void _mostrarFormulario({Map<String, dynamic>? cliente}) {
    final nombreController =
        TextEditingController(text: cliente?['nombre'] ?? '');
    final ciudadController =
        TextEditingController(text: cliente?['ciudad'] ?? '');
    final edadController =
        TextEditingController(text: cliente?['edad']?.toString() ?? '');
    final sexoController =
        TextEditingController(text: cliente?['sexo'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cliente == null ? "Nuevo Cliente" : "Editar Cliente"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: "Nombre")),
              TextField(
                  controller: ciudadController,
                  decoration: const InputDecoration(labelText: "Ciudad")),
              TextField(
                controller: edadController,
                decoration: const InputDecoration(labelText: "Edad"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                  controller: sexoController,
                  decoration: const InputDecoration(labelText: "Sexo")),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (cliente == null) {
                await clientesService.insertarCliente(
                  nombre: nombreController.text,
                  ciudad: ciudadController.text,
                  edad: int.tryParse(edadController.text) ?? 0,
                  sexo: sexoController.text,
                );
              } else {
                await clientesService.actualizarCliente(
                  cliente['id'],
                  nombre: nombreController.text,
                  ciudad: ciudadController.text,
                  edad: int.tryParse(edadController.text) ?? 0,
                  sexo: sexoController.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCliente(int id) async {
    await clientesService.eliminarCliente(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clientes")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: clientesService.streamClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay clientes"));
          }

          final clientes = snapshot.data!;

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return ListTile(
                title: Text(cliente['nombre'] ?? ''),
                subtitle: Text(
                  "Ciudad: ${cliente['ciudad']} | Edad: ${cliente['edad']} | Sexo: ${cliente['sexo']}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _mostrarFormulario(cliente: cliente),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminarCliente(cliente['id']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}