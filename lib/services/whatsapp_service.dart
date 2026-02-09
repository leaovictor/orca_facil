import 'package:url_launcher/url_launcher.dart';
import '../models/budget_model.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

/// Service for WhatsApp integration
class WhatsAppService {
  /// Generate WhatsApp deep link with formatted message
  Future<String> generateWhatsAppLink({
    required String phone,
    required BudgetModel budget,
    required UserModel user,
    String? pdfUrl,
  }) async {
    // Format phone number (remove non-digits and add country code if not present)
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final formattedPhone = cleanPhone.startsWith('55')
        ? cleanPhone
        : '55$cleanPhone';

    // Generate message
    final message = _formatMessage(budget: budget, user: user, pdfUrl: pdfUrl);

    // URL encode the message
    final encodedMessage = Uri.encodeComponent(message);

    // Generate WhatsApp deep link
    return 'https://wa.me/$formattedPhone?text=$encodedMessage';
  }

  /// Format WhatsApp message with budget details
  String _formatMessage({
    required BudgetModel budget,
    required UserModel user,
    String? pdfUrl,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final message = StringBuffer();
    message.writeln('Olá ${budget.clientName}! 👋');
    message.writeln('');
    message.writeln('Segue seu orçamento:');
    message.writeln('');
    message.writeln('📄 *Orçamento Nº ${budget.budgetNumber}*');
    message.writeln('💰 Valor: *${currencyFormat.format(budget.total)}*');
    message.writeln('📅 Validade: ${budget.validityDays} dias');
    message.writeln('🛡️ Garantia: ${budget.warrantyDays} dias');
    message.writeln('');

    if (pdfUrl != null) {
      message.writeln('📎 PDF: $pdfUrl');
      message.writeln('');
    }

    message.writeln('Qualquer dúvida fico à disposição!');
    message.writeln('');
    message.writeln('Atenciosamente,');
    message.writeln(user.name);

    return message.toString();
  }

  /// Launch WhatsApp with the generated link
  Future<bool> sendBudgetViaWhatsApp({
    required String phone,
    required BudgetModel budget,
    required UserModel user,
    String? pdfUrl,
  }) async {
    try {
      final whatsappLink = await generateWhatsAppLink(
        phone: phone,
        budget: budget,
        user: user,
        pdfUrl: pdfUrl,
      );

      final uri = Uri.parse(whatsappLink);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validate phone number
  bool isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Brazil phone numbers: 10 or 11 digits (DDD + number)
    return cleanPhone.length >= 10 && cleanPhone.length <= 13;
  }
}
