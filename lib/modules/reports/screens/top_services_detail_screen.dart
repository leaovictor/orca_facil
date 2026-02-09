import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/report_models.dart';
import '../services/excel_export_service.dart';
import '../../../core/utils/formatters.dart';

class TopServicesDetailScreen extends ConsumerStatefulWidget {
  final TopServicesReport report;

  const TopServicesDetailScreen({super.key, required this.report});

  @override
  ConsumerState<TopServicesDetailScreen> createState() =>
      _TopServicesDetailScreenState();
}

class _TopServicesDetailScreenState
    extends ConsumerState<TopServicesDetailScreen> {
  bool _isExporting = false;
  int _touchedIndex = -1;

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final excelService = ExcelExportService();
      final bytes = await excelService.exportTopServicesToExcel(widget.report);

      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'servicos_${DateFormat('yyyy_MM_dd').format(widget.report.periodStart)}.xlsx',
      );

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
        title: const Text('Serviços Mais Vendidos'),
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
          _buildPeriodCard(),
          const SizedBox(height: 24),
          _buildPieChart(),
          const SizedBox(height: 24),
          _buildRankingList(),
        ],
      ),
    );
  }

  Widget _buildPeriodCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Período Analisado',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(widget.report.periodStart)} - ${DateFormat('dd/MM/yyyy').format(widget.report.periodEnd)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (widget.report.rankings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Nenhum serviço encontrado neste período',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribuição por Serviço',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: widget.report.rankings
                      .take(8)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final isTouched = entry.key == _touchedIndex;
                        final radius = isTouched ? 110.0 : 100.0;
                        final fontSize = isTouched ? 16.0 : 14.0;

                        return PieChartSectionData(
                          color: colors[entry.key % colors.length],
                          value: entry.value.percentage,
                          title:
                              '${entry.value.percentage.toStringAsFixed(1)}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: widget.report.rankings
                  .take(8)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colors[entry.key % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.value.serviceName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ranking Completo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.report.rankings.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final ranking = widget.report.rankings[index];
                final position = index + 1;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: position <= 3
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$position°',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: position <= 3
                              ? Colors.amber[800]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    ranking.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${ranking.quantity} vendas • ${ranking.percentage.toStringAsFixed(1)}% do total',
                  ),
                  trailing: Text(
                    Formatters.formatCurrency(ranking.totalRevenue),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
