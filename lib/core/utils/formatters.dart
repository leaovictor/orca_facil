import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  // Phone input formatter for text fields
  static TextInputFormatter get phoneFormatter =>
      _BrazilianPhoneInputFormatter();

  // Currency formatter for BRL
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  // Phone number formatter (xx) xxxxx-xxxx
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length == 11) {
      return '(${cleaned.substring(0, 2)}) ${cleaned.substring(2, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 2)}) ${cleaned.substring(2, 6)}-${cleaned.substring(6)}';
    }

    return phone;
  }

  // Date formatter
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  // DateTime formatter
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dateTime);
  }

  // Short date formatter
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM', 'pt_BR').format(date);
  }

  // Time formatter
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm', 'pt_BR').format(dateTime);
  }

  // Budget number formatter
  static String formatBudgetNumber(int number) {
    return number.toString().padLeft(6, '0');
  }

  // Parse phone to clean digits
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate phone
  static bool isValidPhone(String phone) {
    final cleaned = cleanPhone(phone);
    return cleaned.length == 10 || cleaned.length == 11;
  }
}

/// Brazilian phone number input formatter
/// Formats: (XX) XXXXX-XXXX or (XX) XXXX-XXXX
class _BrazilianPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Remove all non-digit characters
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 11 digits
    if (digitsOnly.length > 11) {
      return oldValue;
    }

    // Format the phone number
    String formatted = '';

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Add area code
    if (digitsOnly.isNotEmpty) {
      formatted =
          '(${digitsOnly.substring(0, digitsOnly.length >= 2 ? 2 : digitsOnly.length)}';
    }

    // Close parenthesis after area code
    if (digitsOnly.length >= 3) {
      formatted =
          '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2, digitsOnly.length >= 7 ? 7 : digitsOnly.length)}';
    }

    // Add dash before last 4 digits
    if (digitsOnly.length >= 8) {
      if (digitsOnly.length == 11) {
        // Mobile: (XX) XXXXX-XXXX
        formatted =
            '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2, 7)}-${digitsOnly.substring(7)}';
      } else {
        // Landline: (XX) XXXX-XXXX
        formatted =
            '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2, 6)}-${digitsOnly.substring(6)}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
