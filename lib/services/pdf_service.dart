import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/budget_model.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import '../core/utils/formatters.dart';
import '../core/utils/pix_utils.dart';
import '../core/constants/app_constants.dart';

import 'package:intl/date_symbol_data_local.dart';

class PdfService {
  // Generate professional PDF
  Future<Uint8List> generateBudgetPdf({
    required BudgetModel budget,
    required UserModel user,
    required SubscriptionModel subscription,
  }) async {
    // Ensure locale data is initialized
    await initializeDateFormatting('pt_BR', null);

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
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 24),

            // Client information
            _buildClientSection(budget),
            pw.SizedBox(height: 24),

            // Services table
            _buildServicesTable(budget),
            pw.SizedBox(height: 24),

            // Total
            _buildTotalSection(budget),
            pw.SizedBox(height: 24),

            // Payment / Pix Section
            if (user.pixKey != null && user.pixKey!.isNotEmpty)
              _buildPaymentSection(user, budget),

            if (user.pixKey != null && user.pixKey!.isNotEmpty)
              pw.SizedBox(height: 24),

            // Terms
            _buildTermsSection(),
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
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DADOS DO CLIENTE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Nome: ${budget.clientName}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Telefone: ${Formatters.formatPhone(budget.clientPhone)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (budget.clientAddress != null)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Endereço:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        budget.clientAddress!,
                        style: const pw.TextStyle(fontSize: 10),
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
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: pw.FlexColumnWidth(3), // Serviço
        1: pw.FlexColumnWidth(3), // Descrição
        2: pw.FlexColumnWidth(1), // Qtd
        3: pw.FlexColumnWidth(1.5), // Valor Unit.
        4: pw.FlexColumnWidth(1.5), // Total
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableCell('Serviço', isHeader: true),
            _buildTableCell('Descrição', isHeader: true),
            _buildTableCell('Qtd', isHeader: true, align: pw.TextAlign.center),
            _buildTableCell(
              'Valor Unit.',
              isHeader: true,
              align: pw.TextAlign.right,
            ),
            _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...List.generate(budget.items.length, (index) {
          final item = budget.items[index];
          final isEven = index % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.grey100,
            ),
            children: [
              _buildTableCell(item.serviceName),
              _buildTableCell(item.serviceDescription),
              _buildTableCell(
                item.quantity.toString(),
                align: pw.TextAlign.center,
              ),
              _buildTableCell(
                Formatters.formatCurrency(item.unitPrice),
                align: pw.TextAlign.right,
              ),
              _buildTableCell(
                Formatters.formatCurrency(item.total),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
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
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            'TOTAL A PAGAR:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue700,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              Formatters.formatCurrency(budget.total),
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentSection(UserModel user, BudgetModel budget) {
    // Generate Pix Payload
    final pixPayload = PixPayload(
      key: user.pixKey!,
      name: user.name,
      city: 'BRASIL', // Using generic city as discussed
      // amount: budget.total, // Optional: if uncommented, QR code is specific to this amount
    ).generatePayload();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.BarcodeWidget(
            data: pixPayload,
            barcode: pw.Barcode.qrCode(),
            width: 80,
            height: 80,
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PAGAMENTO VIA PIX',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Escaneie o QR Code ao lado ou utilize a chave abaixo para realizar o pagamento.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Chave Pix:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  user.pixKey!,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTermsSection() {
    return pw.Text(
      'Orçamento válido por 15 dias após a data de emissão. Pagamento de 50% na aprovação e 50% na conclusão do serviço.',
      style: pw.TextStyle(
        fontSize: 10,
        color: PdfColors.grey600,
        fontStyle: pw.FontStyle.italic,
      ),
      textAlign: pw.TextAlign.center,
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 32),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Column(
              children: [
                pw.Container(width: 200, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Assinatura do Cliente',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildWatermark() {
    return pw.Positioned(
      bottom: 200,
      left: 0,
      right: 0,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -0.5,
          child: pw.Opacity(
            opacity: 0.1,
            child: pw.Text(
              AppConstants.freeWatermarkText,
              style: pw.TextStyle(
                fontSize: 60,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Share PDF
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '$fileName.pdf',
        body: 'Segue orçamento em anexo',
        subject: 'Orçamento $fileName',
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
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('Failed to load image: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading image: $e');
    }
  }
}
