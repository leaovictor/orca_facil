import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/budget_wizard_providers.dart';
import '../../../viewmodels/budget_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/subscription_viewmodel.dart';

import '../../../core/utils/formatters.dart';
import '../../../widgets/custom_button.dart';

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

      // Generate and share PDF using ViewModel method
      await ref
          .read(budgetViewModelProvider.notifier)
          .generateAndSharePdf(
            budget: createdBudget,
            user: userModel,
            subscription: subscription,
          );

      if (mounted) {
        // Reset wizard
        resetWizard(ref);

        // Show success and return to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar orçamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

          // Client info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cliente',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('Nome', client.name),
                  if (client.phone.isNotEmpty)
                    _buildInfoRow('Telefone', client.phone),
                  if (client.address != null && client.address!.isNotEmpty)
                    _buildInfoRow('Endereço', client.address!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Services card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.build,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Serviços',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.serviceName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity}x ${Formatters.formatCurrency(item.unitPrice)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(item.total),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(total),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
