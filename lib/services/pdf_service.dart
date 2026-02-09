import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/budget_model.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import '../core/utils/formatters.dart';
import '../core/constants/app_constants.dart';

class PdfService {
  // Generate professional PDF
  Future<Uint8List> generateBudgetPdf({
    required BudgetModel budget,
    required UserModel user,
    required SubscriptionModel subscription,
  }) async {
    final pdf = pw.Document();

    // Load logo if available
    pw.MemoryImage? logoImage;
    if (user.logoUrl != null && subscription.tier == SubscriptionTier.pro) {
      try {
        final imageData = await networkImageToBytes(user.logoUrl!);
        logoImage = pw.MemoryImage(imageData);
      } catch (e) {
        // If logo fails to load, continue without it
        logoImage = null;
      }
    } else {
      // Use default logo from assets
      try {
        final bytes = await rootBundle.load('assets/logo/logo.png');
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (e) {
        logoImage = null;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with logo
            _buildHeader(logoImage, user, budget),
            pw.SizedBox(height: 24),
            pw.Divider(thickness: 2, color: PdfColors.blue700),
            pw.SizedBox(height: 24),

            // Client information
            _buildClientSection(budget),
            pw.SizedBox(height: 24),

            // Services table
            _buildServicesTable(budget),
            pw.SizedBox(height: 24),

            // Total
            _buildTotalSection(budget),
            pw.SizedBox(height: 32),

            // Footer with signature
            _buildFooter(),

            // Watermark for free users
            if (subscription.tier == SubscriptionTier.free) _buildWatermark(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    pw.MemoryImage? logo,
    UserModel user,
    BudgetModel budget,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Container(width: 80, height: 80, child: pw.Image(logo)),
            pw.SizedBox(height: 8),
            pw.Text(
              user.name,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            if (user.phone != null)
              pw.Text(
                Formatters.formatPhone(user.phone!),
                style: const pw.TextStyle(fontSize: 12),
              ),
            pw.Text(user.email, style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'ORÇAMENTO',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Nº ${Formatters.formatBudgetNumber(budget.budgetNumber)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Data: ${Formatters.formatDate(budget.createdAt)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildClientSection(BudgetModel budget) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DADOS DO CLIENTE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Nome: ${budget.clientName}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Telefone: ${Formatters.formatPhone(budget.clientPhone)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (budget.clientAddress != null)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Endereço: ${budget.clientAddress}',
                        style: const pw.TextStyle(fontSize: 12),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildServicesTable(BudgetModel budget) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableCell('Serviço', isHeader: true),
            _buildTableCell('Descrição', isHeader: true),
            _buildTableCell('Qtd', isHeader: true),
            _buildTableCell('Valor Unit.', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Items
        ...budget.items.map(
          (item) => pw.TableRow(
            children: [
              _buildTableCell(item.serviceName),
              _buildTableCell(item.serviceDescription),
              _buildTableCell(
                item.quantity.toString(),
                align: pw.TextAlign.center,
              ),
              _buildTableCell(Formatters.formatCurrency(item.unitPrice)),
              _buildTableCell(Formatters.formatCurrency(item.total)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildTotalSection(BudgetModel budget) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue700,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'TOTAL',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              Formatters.formatCurrency(budget.total),
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              width: 200,
              child: pw.Column(
                children: [
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Assinatura do Cliente',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildWatermark() {
    return pw.Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -0.5,
          child: pw.Opacity(
            opacity: 0.2,
            child: pw.Text(
              AppConstants.freeWatermarkText,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Save PDF to device
  Future<String> savePdf(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw Exception('Erro ao salvar PDF: $e');
    }
  }

  // Share PDF
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Orçamento $fileName',
        text: 'Segue orçamento em anexo',
      );
    } catch (e) {
      throw Exception('Erro ao compartilhar PDF: $e');
    }
  }

  // Print PDF
  Future<void> printPdf(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      throw Exception('Erro ao imprimir PDF: $e');
    }
  }

  // Helper to convert network image to bytes
  Future<Uint8List> networkImageToBytes(String url) async {
    final response = await HttpClient().getUrl(Uri.parse(url));
    final bytes = await (await response.close()).fold<List<int>>(
      [],
      (previous, element) => previous..addAll(element),
    );
    return Uint8List.fromList(bytes);
  }
}
