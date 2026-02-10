import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../models/user_model.dart';
import '../core/utils/pix_utils.dart';

final paymentServiceProvider = Provider((ref) => PaymentService());

class PaymentService {
  /// Generates a Pix copy and paste payload using custom PixPayload
  /// PIX key comes from user profile (dynamic per technician)
  /// Amount comes from budget total (dynamic per budget)
  /// Transaction ID uses budget number
  String generatePixPayload({
    required UserModel user,
    required BudgetModel budget,
  }) {
    if (user.pixKey == null || user.pixKey!.isEmpty) {
      return '';
    }

    try {
      // Use custom PixPayload for correct EMV format
      final pixPayload = PixPayload(
        key:
            user.pixKey!, // Dynamic from technician profile (e.g., 01348288442)
        name: 'N', // Simplified as per working example
        city: 'C', // Simplified as per working example
        amount: budget.total, // Dynamic from budget total
        txId: 'ORCAMAIS', // Transaction identifier
      );

      return pixPayload.generatePayload();
    } catch (e) {
      // Return empty string on error
      return '';
    }
  }
}
