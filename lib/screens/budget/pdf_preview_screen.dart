import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../models/budget_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final BudgetModel budget;

  const PdfPreviewScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    final subscription = ref.watch(subscriptionProvider(user.uid)).value;
    if (subscription == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pdfService = ref.read(pdfServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Orçamento #${budget.budgetNumber}')),
      body: PdfPreview(
        build: (format) => pdfService.generateBudgetPdf(
          budget: budget,
          user: user,
          subscription: subscription,
        ),
        canDebug: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        actions: const [], // You can add custom actions here
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
