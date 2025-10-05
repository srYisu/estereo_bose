import 'dart:ui';

import 'package:estereo_bose/pantallas/principal_pantalla.dart';
import 'package:estereo_bose/pantallas/productos_pantalla.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fzvfhnekmculrrnbsdqu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6dmZobmVrbWN1bHJybmJzZHF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkzODA2NzQsImV4cCI6MjA3NDk1NjY3NH0.lWVwSZIHnVuzYjTIj-r1IlwnvvlsHGxwm3gPZUA7puM',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 7, 16, 39),
      ),
      home: const PrincipalPantalla(),
    );
  }
}
