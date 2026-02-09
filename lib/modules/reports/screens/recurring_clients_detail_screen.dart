import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/report_models.dart';
import '../services/excel_export_service.dart';
import '../../../core/utils/formatters.dart';

class RecurringClientsDetailScreen extends ConsumerStatefulWidget {
  final RecurringClientsReport report;

  const RecurringClientsDetailScreen({super.key, required this.report});

  @override
  ConsumerState<RecurringClientsDetailScreen> createState() =>
      _RecurringClientsDetailScreenState();
}

class _RecurringClientsDetailScreenState
    extends ConsumerState<RecurringClientsDetailScreen> {
  bool _isExporting = false;
  String _sortBy = 'count'; // 'count' or 'revenue'

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final excelService = ExcelExportService();
      final bytes = await excelService.exportRecurringClientsToExcel(
        widget.report,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'clientes_recorrentes_${DateFormat('yyyy_MM_dd').format(widget.report.periodStart)}.xlsx',
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

  List<ClientRecurrence> get _sortedClients {
    final clients = List<ClientRecurrence>.from(widget.report.clients);
    if (_sortBy == 'revenue') {
      clients.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    } else {
      clients.sort((a, b) => b.budgetCount.compareTo(a.budgetCount));
    }
    return clients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes Recorrentes'),
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
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildSortOptions(),
          const SizedBox(height: 16),
          _buildClientsList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalClients = widget.report.clients.length;
    final totalRevenue = widget.report.clients.fold<double>(
      0,
      (sum, client) => sum + client.totalRevenue,
    );
    final totalBudgets = widget.report.clients.fold<int>(
      0,
      (sum, client) => sum + client.budgetCount,
    );

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Clientes',
            totalClients.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Orçamentos',
            totalBudgets.toString(),
            Icons.folder,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Receita Total',
            Formatters.formatCurrency(totalRevenue),
            Icons.attach_money,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Text(
              'Ordenar por:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'count',
                    label: Text('Orçamentos'),
                    icon: Icon(Icons.numbers, size: 16),
                  ),
                  ButtonSegment(
                    value: 'revenue',
                    label: Text('Receita'),
                    icon: Icon(Icons.attach_money, size: 16),
                  ),
                ],
                selected: {_sortBy},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _sortBy = newSelection.first;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsList() {
    if (widget.report.clients.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum cliente recorrente encontrado',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clientes com 2+ orçamentos aparecerão aqui',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sortedClients = _sortedClients;

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sortedClients.length,
        separatorBuilder: (context, index) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final client = sortedClients[index];
          final daysSinceFirst = client.lastBudget
              .difference(client.firstBudget)
              .inDays;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        client.clientName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatPhone(client.clientPhone),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(client.totalRevenue),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${client.budgetCount} orçamentos',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Primeiro orçamento',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM/yyyy').format(client.firstBudget),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Último orçamento',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM/yyyy').format(client.lastBudget),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Período',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$daysSinceFirst dias',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
