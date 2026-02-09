import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/report_models.dart';
import '../../../core/utils/formatters.dart';

/// Service for exporting reports to Excel format
class ExcelExportService {
  /// Export monthly revenue report to Excel
  Future<Uint8List> exportMonthlyRevenueToExcel(
    MonthlyRevenueReport report,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Faturamento Mensal'];

    // Header
    sheet.appendRow([TextCellValue('RELATÓRIO DE FATURAMENTO MENSAL')]);
    sheet.appendRow([TextCellValue('Período: ${report.formattedMonth}')]);
    sheet.appendRow([]); // Empty row

    // Summary
    sheet.appendRow([TextCellValue('RESUMO')]);
    sheet.appendRow([
      TextCellValue('Faturamento Total'),
      TextCellValue(Formatters.formatCurrency(report.totalRevenue)),
    ]);
    sheet.appendRow([
      TextCellValue('Orçamentos'),
      IntCellValue(report.budgetCount),
    ]);
    sheet.appendRow([
      TextCellValue('Ticket Médio'),
      TextCellValue(Formatters.formatCurrency(report.averageTicket)),
    ]);
    sheet.appendRow([]); // Empty row

    // Revenue by service
    sheet.appendRow([TextCellValue('FATURAMENTO POR SERVIÇO')]);
    sheet.appendRow([TextCellValue('Serviço'), TextCellValue('Receita')]);

    final sortedServices = report.revenueByService.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedServices) {
      sheet.appendRow([
        TextCellValue(entry.key),
        TextCellValue(Formatters.formatCurrency(entry.value)),
      ]);
    }

    sheet.appendRow([]); // Empty row

    // Daily breakdown
    sheet.appendRow([TextCellValue('FATURAMENTO DIÁRIO')]);
    sheet.appendRow([
      TextCellValue('Data'),
      TextCellValue('Receita'),
      TextCellValue('Orçamentos'),
    ]);

    for (final daily in report.dailyBreakdown) {
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(daily.date)),
        TextCellValue(Formatters.formatCurrency(daily.revenue)),
        IntCellValue(daily.budgetCount),
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Export top services report to Excel
  Future<Uint8List> exportTopServicesToExcel(TopServicesReport report) async {
    final excel = Excel.createExcel();
    final sheet = excel['Serviços Mais Vendidos'];

    // Header
    sheet.appendRow([TextCellValue('SERVIÇOS MAIS VENDIDOS')]);
    sheet.appendRow([
      TextCellValue(
        'Período: ${DateFormat('dd/MM/yyyy').format(report.periodStart)} - ${DateFormat('dd/MM/yyyy').format(report.periodEnd)}',
      ),
    ]);
    sheet.appendRow([]); // Empty row

    // Rankings table
    sheet.appendRow([
      TextCellValue('Posição'),
      TextCellValue('Serviço'),
      TextCellValue('Quantidade'),
      TextCellValue('Receita Total'),
      TextCellValue('% do Total'),
    ]);

    for (int i = 0; i < report.rankings.length; i++) {
      final ranking = report.rankings[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(ranking.serviceName),
        IntCellValue(ranking.quantity),
        TextCellValue(Formatters.formatCurrency(ranking.totalRevenue)),
        TextCellValue('${ranking.percentage.toStringAsFixed(1)}%'),
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Export recurring clients report to Excel
  Future<Uint8List> exportRecurringClientsToExcel(
    RecurringClientsReport report,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Clientes Recorrentes'];

    // Header
    sheet.appendRow([TextCellValue('CLIENTES RECORRENTES')]);
    sheet.appendRow([
      TextCellValue(
        'Período: ${DateFormat('dd/MM/yyyy').format(report.periodStart)} - ${DateFormat('dd/MM/yyyy').format(report.periodEnd)}',
      ),
    ]);
    sheet.appendRow([]); // Empty row

    // Summary
    sheet.appendRow([
      TextCellValue('Total de Clientes Recorrentes: ${report.clients.length}'),
    ]);
    sheet.appendRow([]); // Empty row

    // Client table
    sheet.appendRow([
      TextCellValue('Cliente'),
      TextCellValue('Telefone'),
      TextCellValue('Orçamentos'),
      TextCellValue('Receita Total'),
      TextCellValue('Primeiro Orçamento'),
      TextCellValue('Último Orçamento'),
    ]);

    for (final client in report.clients) {
      sheet.appendRow([
        TextCellValue(client.clientName),
        TextCellValue(Formatters.formatPhone(client.clientPhone)),
        IntCellValue(client.budgetCount),
        TextCellValue(Formatters.formatCurrency(client.totalRevenue)),
        TextCellValue(DateFormat('dd/MM/yyyy').format(client.firstBudget)),
        TextCellValue(DateFormat('dd/MM/yyyy').format(client.lastBudget)),
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Export month comparison report to Excel
  Future<Uint8List> exportMonthComparisonToExcel(
    MonthComparisonReport report,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Comparação Mensal'];

    // Header
    sheet.appendRow([TextCellValue('COMPARAÇÃO ENTRE MESES')]);
    sheet.appendRow([
      TextCellValue(
        '${DateFormat('MMMM/yyyy', 'pt_BR').format(report.month1)} vs ${DateFormat('MMMM/yyyy', 'pt_BR').format(report.month2)}',
      ),
    ]);
    sheet.appendRow([]); // Empty row

    // Comparison table
    sheet.appendRow([
      TextCellValue('Métrica'),
      TextCellValue(DateFormat('MMM/yy', 'pt_BR').format(report.month1)),
      TextCellValue(DateFormat('MMM/yy', 'pt_BR').format(report.month2)),
      TextCellValue('Variação'),
    ]);

    sheet.appendRow([
      TextCellValue('Faturamento'),
      TextCellValue(Formatters.formatCurrency(report.month1Stats.totalRevenue)),
      TextCellValue(Formatters.formatCurrency(report.month2Stats.totalRevenue)),
      TextCellValue(
        '${report.comparison.revenueChange >= 0 ? '+' : ''}${report.comparison.revenueChange.toStringAsFixed(1)}%',
      ),
    ]);

    sheet.appendRow([
      TextCellValue('Orçamentos'),
      IntCellValue(report.month1Stats.budgetCount),
      IntCellValue(report.month2Stats.budgetCount),
      TextCellValue(
        '${report.comparison.budgetCountChange >= 0 ? '+' : ''}${report.comparison.budgetCountChange}',
      ),
    ]);

    sheet.appendRow([
      TextCellValue('Ticket Médio'),
      TextCellValue(
        Formatters.formatCurrency(report.month1Stats.averageTicket),
      ),
      TextCellValue(
        Formatters.formatCurrency(report.month2Stats.averageTicket),
      ),
      TextCellValue(
        '${report.comparison.averageTicketChange >= 0 ? '+' : ''}${report.comparison.averageTicketChange.toStringAsFixed(1)}%',
      ),
    ]);

    return Uint8List.fromList(excel.encode()!);
  }
}
