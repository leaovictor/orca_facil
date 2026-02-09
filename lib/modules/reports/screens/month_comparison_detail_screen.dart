import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/report_models.dart';
import '../services/excel_export_service.dart';
import '../../../core/utils/formatters.dart';

class MonthComparisonDetailScreen extends ConsumerStatefulWidget {
  final MonthComparisonReport report;

  const MonthComparisonDetailScreen({super.key, required this.report});

  @override
  ConsumerState<MonthComparisonDetailScreen> createState() =>
      _MonthComparisonDetailScreenState();
}

class _MonthComparisonDetailScreenState
    extends ConsumerState<MonthComparisonDetailScreen> {
  bool _isExporting = false;

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final excelService = ExcelExportService();
      final bytes = await excelService.exportMonthComparisonToExcel(
        widget.report,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'comparacao_${DateFormat('yyyy_MM').format(widget.report.month1)}_vs_${DateFormat('yyyy_MM').format(widget.report.month2)}.xlsx',
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
        title: const Text('Comparação entre Meses'),
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
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _buildComparisonCards(),
          const SizedBox(height: 24),
          _buildGrowthIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.purple.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMonthLabel(widget.report.month1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.compare_arrows,
                    color: Colors.purple.shade700,
                    size: 32,
                  ),
                ),
                _buildMonthLabel(widget.report.month2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthLabel(DateTime month) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Text(
        DateFormat('MMMM/yyyy', 'pt_BR').format(month),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.purple.shade900,
        ),
      ),
    );
  }

  Widget _buildComparisonCards() {
    return Column(
      children: [
        _buildMetricComparison(
          'Faturamento',
          widget.report.month1Stats.totalRevenue,
          widget.report.month2Stats.totalRevenue,
          widget.report.comparison.revenueChange,
          Icons.attach_money,
          Colors.green,
          isPercentage: true,
          isCurrency: true,
        ),
        const SizedBox(height: 12),
        _buildMetricComparison(
          'Orçamentos',
          widget.report.month1Stats.budgetCount.toDouble(),
          widget.report.month2Stats.budgetCount.toDouble(),
          widget.report.comparison.budgetCountChange.toDouble(),
          Icons.folder,
          Colors.blue,
          isPercentage: false,
          isCurrency: false,
        ),
        const SizedBox(height: 12),
        _buildMetricComparison(
          'Ticket Médio',
          widget.report.month1Stats.averageTicket,
          widget.report.month2Stats.averageTicket,
          widget.report.comparison.averageTicketChange,
          Icons.trending_up,
          Colors.orange,
          isPercentage: true,
          isCurrency: true,
        ),
      ],
    );
  }

  Widget _buildMetricComparison(
    String title,
    double value1,
    double value2,
    double change,
    IconData icon,
    Color color, {
    required bool isPercentage,
    required bool isCurrency,
  }) {
    final isPositive = change >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'MMM/yy',
                          'pt_BR',
                        ).format(widget.report.month1),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCurrency
                            ? Formatters.formatCurrency(value1)
                            : value1.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 16, color: changeColor),
                      const SizedBox(width: 4),
                      Text(
                        isPercentage
                            ? '${change.abs().toStringAsFixed(1)}%'
                            : change.abs().toInt().toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat(
                          'MMM/yy',
                          'pt_BR',
                        ).format(widget.report.month2),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCurrency
                            ? Formatters.formatCurrency(value2)
                            : value2.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthIndicator() {
    final revenueChange = widget.report.comparison.revenueChange;
    final isPositive = revenueChange >= 0;

    return Card(
      color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 48,
              color: isPositive ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              isPositive ? 'Crescimento' : 'Queda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: isPositive
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                ),
                children: [
                  const TextSpan(text: 'O faturamento '),
                  TextSpan(
                    text: isPositive ? 'aumentou ' : 'diminuiu ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '${revenueChange.abs().toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' de ${DateFormat('MMM/yy', 'pt_BR').format(widget.report.month1)} '
                        'para ${DateFormat('MMM/yy', 'pt_BR').format(widget.report.month2)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
