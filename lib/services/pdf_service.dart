import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/budget_model.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import '../core/utils/formatters.dart';
import '../services/payment_service.dart';
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

    // Load User Logo if available
    pw.MemoryImage? logoImage;
    if (user.logoUrl != null && subscription.tier != SubscriptionTier.free) {
      try {
        final imageData = await networkImageToBytes(user.logoUrl!);
        logoImage = pw.MemoryImage(imageData);
      } catch (e) {
        logoImage = null;
      }
    }

    // Load Orça+ Logo (App Branding) fallback
    pw.MemoryImage? appLogo;
    try {
      final logoData = await rootBundle.load('assets/logo/logo.png');
      appLogo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      appLogo = null;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header
            _buildHeader(logoImage ?? appLogo, user, budget, boldFont),

            // Status Banner if Paid
            if (budget.status == BudgetStatus.paid) ...[
              pw.SizedBox(height: 10),
              _buildStatusBanner(
                'ORÇAMENTO PAGO',
                PdfColors.green900,
                PdfColors.green100,
              ),
            ],

            pw.SizedBox(height: 20),

            // 2. Client Info
            _buildClientSection(budget),
            pw.SizedBox(height: 24),

            // 3. Services Table
            _buildServicesTable(budget),
            pw.SizedBox(height: 24),

            // 4. Payment & QR (Optional)
            if (budget.status != BudgetStatus.paid &&
                user.pixKey != null &&
                user.pixKey!.isNotEmpty) ...[
              _buildPaymentSection(user, budget),
              pw.SizedBox(height: 24),
            ],

            // 5. Conditions & Terms
            _buildTermsSection(budget),
            pw.SizedBox(height: 40),

            // 6. Signature
            _buildSignatureBlock(),

            // Watermark for FREE tier
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
    pw.Font boldFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (logo != null)
          pw.Container(width: 80, height: 80, child: pw.Image(logo))
        else
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                user.name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'SOLUÇÕES ELÉTRICAS',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                  font: boldFont,
                ),
              ),
            ],
          ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'PROPOSTA COMERCIAL',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                font: boldFont,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Nº ${Formatters.formatBudgetNumber(budget.budgetNumber)}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                font: boldFont,
              ),
            ),
            pw.Text(
              'Emissão: ${Formatters.formatDate(budget.createdAt)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildClientSection(BudgetModel budget) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.blue900, width: 4),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CLIENTE',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            budget.clientName,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            Formatters.formatPhone(budget.clientPhone),
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (budget.clientAddress != null)
            pw.Text(
              budget.clientAddress!,
              style: const pw.TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildServicesTable(BudgetModel budget) {
    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Serviço
        1: const pw.FlexColumnWidth(2), // Detalhes
        2: const pw.FlexColumnWidth(0.8), // Qtd
        3: const pw.FlexColumnWidth(1.2), // V. Unit
        4: const pw.FlexColumnWidth(1.2), // Total
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            _buildTableHeader('SERVIÇO'),
            _buildTableHeader('ESPECIFICAÇÕES'),
            _buildTableHeader('QTD', align: pw.TextAlign.center),
            _buildTableHeader('UNITÁRIO', align: pw.TextAlign.right),
            _buildTableHeader('TOTAL', align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...budget.items.map(
          (item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.serviceName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      item.serviceDescription,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (item.difficulty != null)
                      _buildDetailText('Dificuldade: ${item.difficulty}'),
                    if (item.environment != null)
                      _buildDetailText('Ambiente: ${item.environment}'),
                    if (item.distance != null && item.distance! > 0)
                      _buildDetailText('Distância: ${item.distance}m'),
                  ],
                ),
              ),
              _buildTableBody(
                item.quantity.toString(),
                align: pw.TextAlign.center,
              ),
              _buildTableBody(
                Formatters.formatCurrency(item.unitPrice),
                align: pw.TextAlign.right,
              ),
              _buildTableBody(
                Formatters.formatCurrency(item.total),
                align: pw.TextAlign.right,
                isBold: true,
              ),
            ],
          ),
        ),
        // Summary Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                'VALOR TOTAL',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                Formatters.formatCurrency(budget.total),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  color: PdfColors.blue900,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildTableBody(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildDetailText(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
    );
  }

  pw.Widget _buildPaymentSection(UserModel user, BudgetModel budget) {
    final paymentService = PaymentService();
    final pixPayload = paymentService.generatePixPayload(
      user: user,
      budget: budget,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          if (pixPayload.isNotEmpty)
            pw.BarcodeWidget(
              data: pixPayload,
              barcode: pw.Barcode.qrCode(),
              width: 80,
              height: 80,
            ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PAGAMENTO FACILITADO (PIX)',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Aponte a câmera para pagar ou use a chave abaixo:',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Chave: ${user.pixKey}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatusBanner(
    String text,
    PdfColor textColor,
    PdfColor bgColor,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: textColor,
          fontWeight: pw.FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  pw.Widget _buildTermsSection(BudgetModel budget) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TERMOS E CONDIÇÕES',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 8),
        _buildTermRow(
          'Validade:',
          'Esta proposta é válida por ${budget.validityDays} dias corridos.',
        ),
        _buildTermRow(
          'Garantia:',
          'Oferecemos garantia técnica de ${budget.warrantyDays} dias para os serviços listados.',
        ),
        _buildTermRow('Pagamento:', 'A combinar diretamente com o prestador.'),
      ],
    );
  }

  pw.Widget _buildTermRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          text: '$label ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          children: [
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSignatureBlock() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Column(
          children: [
            pw.Container(width: 250, height: 1, color: PdfColors.grey600),
            pw.SizedBox(height: 4),
            pw.Text(
              'Aceite do Cliente',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildWatermark() {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -0.5, // ~-30 degrees diagonal
          child: pw.Opacity(
            opacity: 0.15,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'VERSÃO GRATUITA',
                  style: pw.TextStyle(
                    fontSize: 70,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Orça+',
                  style: pw.TextStyle(
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
              ],
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
        body: 'Segue proposta de serviços elétricos em anexo.',
        subject: 'Proposta $fileName',
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
