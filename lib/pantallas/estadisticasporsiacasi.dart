import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EstadisticasPantalla extends StatefulWidget {
  const EstadisticasPantalla({Key? key}) : super(key: key);

  @override
  _EstadisticasPantallaState createState() => _EstadisticasPantallaState();
}

class _EstadisticasPantallaState extends State<EstadisticasPantalla> {
  final supabase = Supabase.instance.client;

  int cantidadVentasMes = 0;
  Map<String, dynamic>? clienteTopGasto;
  List<Map<String, dynamic>> clientesPorCiudad = [];
  List<Map<String, dynamic>> clientesPorSexo = [];
  List<Map<String, dynamic>> ventasPorCategoria = [];
  Map<String, dynamic>? productoMasVendido;
  double promedioVentasCliente = 0;
  double totalVentasAnual = 0;
  double totalVentasMes = 0;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarEstadisticas();
  }

  Future<void> cargarEstadisticas() async {
    try {
      final cantidad = await supabase.rpc('cantidad_ventas_mes');
      final clienteTop = await supabase.rpc('cliente_top_gasto');
      final ciudades = await supabase.rpc('clientes_por_ciudad');
      final sexo = await supabase.rpc('porcentaje_clientes_por_sexo');
      final categorias = await supabase.rpc('porcentaje_ventas_por_categoria');
      final producto = await supabase.rpc('producto_mas_vendido');
      final promedio = await supabase.rpc('promedio_ventas_por_cliente');
      final totalAnual = await supabase.rpc('total_ventas_anual');
      final totalMes = await supabase.rpc('total_ventas_mes');

      setState(() {
        cantidadVentasMes = (cantidad as num?)?.toInt() ?? 0;

        if (clienteTop is List && clienteTop.isNotEmpty) {
          clienteTopGasto = {
            'nombre': clienteTop[0]['nombre'],
            'gasto_total':
                (clienteTop[0]['gasto_total'] as num?)?.toDouble() ?? 0,
          };
        }

        clientesPorCiudad =
            (ciudades as List<dynamic>?)
                ?.map(
                  (c) => {
                    'ciudad': c['ciudad'],
                    'cantidad': (c['cantidad'] as num?)?.toDouble() ?? 0,
                  },
                )
                .toList() ??
            [];

        ventasPorCategoria =
            (categorias as List<dynamic>?)
                ?.map(
                  (c) => {
                    'categoria': c['categoria'],
                    'porcentaje': (c['porcentaje'] as num?)?.toDouble() ?? 0,
                    'cantidad': (c['cantidad'] as num?)?.toInt() ?? 0,
                  },
                )
                .toList() ??
            [];

        clientesPorSexo =
            (sexo as List<dynamic>?)
                ?.map(
                  (s) => {
                    'sexo': s['sexo'],
                    'porcentaje': (s['porcentaje'] as num?)?.toDouble() ?? 0,
                    'cantidad': (s['cantidad'] as num?)?.toInt() ?? 0,
                  },
                )
                .toList() ??
            [];

        if (producto is List && producto.isNotEmpty) {
          productoMasVendido = {
            'nombre': producto[0]['nombre'],
            'unidades': (producto[0]['unidades'] as num?)?.toInt() ?? 0,
          };
        }

        promedioVentasCliente = (promedio as num?)?.toDouble() ?? 0;
        totalVentasAnual = (totalAnual as num?)?.toDouble() ?? 0;
        totalVentasMes = (totalMes as num?)?.toDouble() ?? 0;

        cargando = false;
      });
    } catch (e) {
      print("Error cargando estadísticas: $e");
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text("Estadísticas")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A2236),
      appBar: AppBar(
        title: const Text("Estadísticas de Ventas"),
        backgroundColor: const Color(0xFF1A2236),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          children: [
            // Total ventas mes
            _dashboardCard(
              color: const Color(0xFF19D3C5),
              title: "TOTAL VENTAS ESTE MES",
              value: "€${totalVentasMes.toStringAsFixed(2)}",
              subtitle: "+8.5% vs last month",
              valueStyle: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Producto más vendido
            _dashboardCard(
              color: const Color(0xFF2B4C7E),
              title: "PRODUCTO MÁS VENDIDO",
              value: productoMasVendido != null
                  ? "${productoMasVendido!['nombre']}\n${productoMasVendido!['unidades']} Unidades"
                  : "Sin datos",
              valueStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Promedio ventas por cliente
            _dashboardCard(
              color: const Color(0xFFF7A35C),
              title: "PROMEDIO VENTAS / CLIENTE",
              value: "€${promedioVentasCliente.toStringAsFixed(2)}",
              valueStyle: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Cliente top gasto
            _dashboardCard(
              color: const Color(0xFF7B5CF7),
              title: "CLIENTE TOP GASTO",
              value: clienteTopGasto != null
                  ? "€${clienteTopGasto!['gasto_total'].toStringAsFixed(2)}\n${clienteTopGasto!['nombre']}"
                  : "Sin datos",
              valueStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Ventas por categoría (Pie chart)
            // ...existing code...
            // Ventas por categoría (Pie chart + leyenda)
            Card(
              color: const Color(0xFF232B3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "VENTAS POR CATEGORÍA",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          // Pie chart
                          Expanded(
                            flex: 2,
                            child: ventasPorCategoria.isNotEmpty
                                ? PieChart(
                                    PieChartData(
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 2,
                                      sections: ventasPorCategoria.map((c) {
                                        final color =
                                            Colors.primaries[ventasPorCategoria
                                                    .indexOf(c) %
                                                Colors.primaries.length];
                                        return PieChartSectionData(
                                          value: c['porcentaje'],
                                          title: "",
                                          radius: 50,
                                          color: color,
                                        );
                                      }).toList(),
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      "Sin datos",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                          ),
                          // Leyenda
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: ventasPorCategoria.map((c) {
                                final color =
                                    Colors.primaries[ventasPorCategoria.indexOf(
                                          c,
                                        ) %
                                        Colors.primaries.length];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${c['categoria']}  •  ${c['cantidad']}  •  ${c['porcentaje'].toStringAsFixed(0)}%",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ...existing code...
            // ...existing code...
            // Clientes por sexo (Pie chart)
            Card(
              color: const Color(0xFF232B3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text(
                      "CLIENTES POR SEXO",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          // Pie chart
                          Expanded(
                            flex: 2,
                            child: clientesPorSexo.isNotEmpty
                                ? PieChart(
                                    PieChartData(
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 2,
                                      sections: clientesPorSexo.map((s) {
                                        final color =
                                            Colors.primaries[clientesPorSexo
                                                    .indexOf(s) %
                                                Colors.primaries.length];
                                        return PieChartSectionData(
                                          value: s['porcentaje'],
                                          title: "",
                                          radius: 50,
                                          color: color,
                                        );
                                      }).toList(),
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      "Sin datos",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                          ),
                          // Leyenda
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: clientesPorSexo.map((s) {
                                final color =
                                    Colors.primaries[clientesPorSexo.indexOf(
                                          s,
                                        ) %
                                        Colors.primaries.length];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${s['sexo']}  •  ${s['cantidad']}  •  ${s['porcentaje'].toStringAsFixed(0)}%",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ...existing code...
            // Clientes por ciudad (Bar chart)
            Card(
              color: const Color(0xFF232B3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text(
                      "CLIENTES POR CIUDAD",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: clientesPorCiudad.isNotEmpty
                          ? BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                barGroups: clientesPorCiudad.map((c) {
                                  return BarChartGroupData(
                                    x: clientesPorCiudad.indexOf(c),
                                    barRods: [
                                      BarChartRodData(
                                        toY: c['cantidad'],
                                        color:
                                            Colors.primaries[clientesPorCiudad
                                                    .indexOf(c) %
                                                Colors.primaries.length],
                                        width: 20,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget:
                                          (double value, TitleMeta meta) {
                                            int index = value.toInt();
                                            if (index <
                                                clientesPorCiudad.length) {
                                              return Text(
                                                clientesPorCiudad[index]['ciudad'],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const Center(
                              child: Text(
                                "Sin datos",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required Color color,
    required String title,
    required String value,
    String? subtitle,
    TextStyle? valueStyle,
  }) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style:
                  valueStyle ??
                  const TextStyle(color: Colors.white, fontSize: 20),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
