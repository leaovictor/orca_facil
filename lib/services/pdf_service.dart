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

    // Initialize Fonts
    pw.Font baseFont;
    pw.Font boldFont;
    try {
      baseFont = await PdfGoogleFonts.notoSansRegular();
      boldFont = await PdfGoogleFonts.notoSansBold();
    } catch (e) {
      // Fallback to standard fonts if internet fails
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
    );

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
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // 1. Header & Identification
            _buildHeader(logoImage, user, budget),
            pw.SizedBox(height: 12),

            // Client Block (Unified)
            // Using Wrap to ensure it stays together if possible, though Container usually handles this.
            _buildClientSection(budget),
            pw.SizedBox(height: 16),

            // 2. Services Table (Optimized)
            _buildServicesTable(budget),
            pw.SizedBox(height: 16),

            // 3. Payment & Conditions
            if (user.pixKey != null && user.pixKey!.isNotEmpty) ...[
              _buildPaymentSection(user, budget),
              pw.SizedBox(height: 12),
            ],

            // Rules Text
            _buildTermsSection(),
            pw.SizedBox(height: 24),

            // Signature
            _buildFooter(),

            // 4. Watermark (Monetization)
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
        // Left: Logo + User Info
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.Container(
                  width: 60,
                  height: 60,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(logo),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      user.name,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (user.phone != null)
                      pw.Text(
                        Formatters.formatPhone(user.phone!),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    pw.Text(
                      user.email,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Right: Budget Summary
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'ORÇAMENTO',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Nº ${Formatters.formatBudgetNumber(budget.budgetNumber)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Data: ${Formatters.formatDate(budget.createdAt)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildClientSection(BudgetModel budget) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.RichText(
                  text: pw.TextSpan(
                    text: 'Nome: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                    children: [
                      pw.TextSpan(
                        text: budget.clientName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ),
              if (budget.clientPhone.isNotEmpty)
                pw.Expanded(
                  flex: 1,
                  child: pw.RichText(
                    text: pw.TextSpan(
                      text: 'Tel: ',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                      children: [
                        pw.TextSpan(
                          text: Formatters.formatPhone(budget.clientPhone),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (budget.clientAddress != null &&
              budget.clientAddress!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.RichText(
              text: pw.TextSpan(
                text: 'Endereço: ',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                children: [
                  pw.TextSpan(
                    text: budget.clientAddress!,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildServicesTable(BudgetModel budget) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Serviço
        1: const pw.FlexColumnWidth(3), // Descrição
        2: const pw.FlexColumnWidth(1), // Qtd
        3: const pw.FlexColumnWidth(1.5), // V. Unit
        4: const pw.FlexColumnWidth(1.5), // Total
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
              'V. Unit',
              isHeader: true,
              align: pw.TextAlign.right,
            ),
            _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Services Items
        ...budget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isEven = index % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.grey50,
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
        // Total Line
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 6,
              ),
              child: pw.Text(
                'TOTAL:',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 6,
              ),
              child: pw.Text(
                Formatters.formatCurrency(budget.total),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.blue700,
                ),
              ),
            ),
          ],
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
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

  pw.Widget _buildPaymentSection(UserModel user, BudgetModel budget) {
    // Generate Pix Payload
    final pixPayload = PixPayload(
      key: user.pixKey!,
      name: user.name,
      city: 'BRASIL',
      // amount: budget.total, // Optional
    ).generatePayload();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          // QR Code
          pw.BarcodeWidget(
            data: pixPayload,
            barcode: pw.Barcode.qrCode(),
            width: 70,
            height: 70,
          ),
          pw.SizedBox(width: 16),
          // Info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PAGAMENTO VIA PIX',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Escaneie o QR Code ou use a chave abaixo:',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Chave Pix: ${user.pixKey}',
                  style: pw.TextStyle(
                    fontSize: 11,
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
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        'Orçamento válido por 15 dias. Pagamento de 50% na aprovação e 50% na conclusão.',
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey700,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
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
      bottom: 20,
      left: 0,
      right: 0,
      child: pw.Center(
        child: pw.Opacity(
          opacity: 0.5,
          child: pw.Text(
            'OrçaFácil - Versão Gratuita',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500),
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
