import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pix_flutter/pix_flutter.dart';
import '../models/budget_model.dart';
import '../models/user_model.dart';

final paymentServiceProvider = Provider((ref) => PaymentService());

class PaymentService {
  /// Generates a Pix copy and paste payload using pix_flutter
  String generatePixPayload({
    required UserModel user,
    required BudgetModel budget,
  }) {
    if (user.pixKey == null || user.pixKey!.isEmpty) {
      return '';
    }

    try {
      // Proper usage of pix_flutter
      final payload = Payload(
        pixKey: user.pixKey!,
        description: 'Orcamento #${budget.budgetNumber}',
        merchantName: user.name,
        merchantCity: 'SAO PAULO',
        amount: budget.total.toStringAsFixed(2),
        txid: 'ORCA${budget.budgetNumber}',
      );

      final pixFlutter = PixFlutter(payload: payload);

      return pixFlutter.getQRCode();
    } catch (e) {
      // Fallback or rethrow
      return '';
    }
  }
}
