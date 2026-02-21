import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/budget_wizard_providers.dart';
import '../../../viewmodels/budget_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/subscription_viewmodel.dart';

import '../../../widgets/custom_button.dart';
import 'summary_card.dart';

class SummaryStep extends ConsumerStatefulWidget {
  const SummaryStep({super.key});

  @override
  ConsumerState<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends ConsumerState<SummaryStep> {
  bool _isCreating = false;

  Future<void> _createBudget() async {
    final client = ref.read(selectedClientProvider);
    final items = ref.read(selectedServicesProvider);
    final user = ref.read(authStateProvider).value;

    if (client == null || items.isEmpty || user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dados incompletos')));
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Create budget using ViewModel (handles budgetNumber generation)
      final budgetId = await ref
          .read(budgetViewModelProvider.notifier)
          .createBudget(userId: user.uid, client: client, items: items);

      if (budgetId == null) {
        throw Exception('Erro ao criar orçamento');
      }

      // Get the created budget from the state
      final createdBudget = ref.read(budgetViewModelProvider).value;

      if (createdBudget == null) {
        throw Exception('Orçamento não encontrado após criação');
      }

      // Get UserModel and SubscriptionModel for PDF generation
      final userModelAsync = ref.read(currentUserProvider);
      final userModel = userModelAsync.value;

      if (userModel == null) {
        throw Exception('Dados do usuário não encontrados');
      }

      final subscriptionAsync = ref.read(subscriptionProvider(user.uid));
      final subscription = subscriptionAsync.value;

      if (subscription == null) {
        throw Exception('Dados da assinatura não encontrados');
      }

      if (mounted) {
        // Reset wizard
        resetWizard(ref);

        // Show success and navigate to preview
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Replace the wizard with the preview screen
        // This ensures the back button goes to the previous screen (likely the budget list)
        context.pushReplacement('/budget/preview', extra: createdBudget);
      }
    } catch (e) {
      setState(() => _isCreating = false);

      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('limite') ||
            errorMessage.contains('upgrade')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Limite Atingido 🚀'),
              content: const Text(
                'Você atingiu o limite de 5 orçamentos gratuitos deste mês.\n\nFaça um upgrade para o plano Pro e crie orçamentos ILIMITADOS!',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Depois'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/subscription');
                  },
                  child: const Text('Ver Planos'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar orçamento: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(selectedClientProvider);
    final items = ref.watch(selectedServicesProvider);
    final total = ref.watch(budgetTotalProvider);

    if (client == null) {
      return const Center(child: Text('Cliente não selecionado'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Resumo do Orçamento',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Confira os dados antes de finalizar',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Reusable Summary Card
          SummaryCard(
            client: client,
            items: items,
            total: total,
            onEditClient: () =>
                ref.read(currentStepProvider.notifier).state = 0,
            onEditServices: () =>
                ref.read(currentStepProvider.notifier).state = 1,
          ),
          const SizedBox(height: 24),

          // Action buttons
          CustomButton(
            text: 'Finalizar e Gerar PDF',
            onPressed: _createBudget,
            isLoading: _isCreating,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isCreating
                  ? null
                  : () {
                      ref.read(currentStepProvider.notifier).state = 1;
                    },
              child: const Text('Voltar'),
            ),
          ),
        ],
      ),
    );
  }
}
