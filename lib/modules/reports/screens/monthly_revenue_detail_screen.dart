import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/report_models.dart';
import '../services/excel_export_service.dart';
import '../../../core/utils/formatters.dart';

class MonthlyRevenueDetailScreen extends ConsumerStatefulWidget {
  final MonthlyRevenueReport report;

  const MonthlyRevenueDetailScreen({super.key, required this.report});

  @override
  ConsumerState<MonthlyRevenueDetailScreen> createState() =>
      _MonthlyRevenueDetailScreenState();
}

class _MonthlyRevenueDetailScreenState
    extends ConsumerState<MonthlyRevenueDetailScreen> {
  bool _isExporting = false;

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final excelService = ExcelExportService();
      final bytes = await excelService.exportMonthlyRevenueToExcel(
        widget.report,
      );

      final directory = await getTemporaryDirectory();
      final fileName =
          'faturamento_${DateFormat('yyyy_MM').format(widget.report.month)}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Relatório de Faturamento Mensal');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatório exportado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.report.formattedMonth),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportToExcel,
            tooltip: 'Exportar para Excel',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricsCards(),
          const SizedBox(height: 24),
          _buildDailyRevenueChart(),
          const SizedBox(height: 24),
          _buildServiceBreakdown(),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Faturamento Total',
            Formatters.formatCurrency(widget.report.totalRevenue),
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Orçamentos',
            widget.report.budgetCount.toString(),
            Icons.folder,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Ticket Médio',
            Formatters.formatCurrency(widget.report.averageTicket),
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faturamento Diário',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'R\$ ${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: widget.report.dailyBreakdown.asMap().entries.map((
                        entry,
                      ) {
                        return FlSpot(
                          entry.value.date.day.toDouble(),
                          entry.value.revenue,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
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

  Widget _buildServiceBreakdown() {
    final sortedServices = widget.report.revenueByService.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faturamento por Serviço',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedServices.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final entry = sortedServices[index];
                final percentage =
                    (entry.value / widget.report.totalRevenue) * 100;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  subtitle: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
