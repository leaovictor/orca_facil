import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/budget_wizard_providers.dart';
import '../../../widgets/constrained_layout.dart';
import 'steps/client_step.dart';
import 'steps/service_step.dart';
import 'steps/summary_step.dart';
import 'steps/summary_card.dart';

class NewBudgetScreen extends ConsumerWidget {
  const NewBudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(currentStepProvider);
    final canProceed = ref.watch(canProceedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Orçamento'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showExitDialog(context, ref);
          },
        ),
      ),
      body: ConstrainedLayout(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Desktop Split View (Width >= 900)
            if (constraints.maxWidth >= 900) {
              return _buildDesktopLayout(context, ref, currentStep, canProceed);
            }

            // Mobile/Tablet Stepper View
            return _buildMobileLayout(context, ref, currentStep, canProceed);
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    int currentStep,
    bool canProceed,
  ) {
    // Watch data for real-time summary
    final client = ref.watch(selectedClientProvider);
    final items = ref.watch(selectedServicesProvider);
    final total = ref.watch(budgetTotalProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COL: Form Steps (Flex 3)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildStepIndicator(context, currentStep),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: IndexedStack(
                    index: currentStep,
                    children: const [
                      ClientStep(),
                      ServiceStep(),
                      SummaryStep(), // Reuse SummaryStep logic for final confirmation
                    ],
                  ),
                ),
              ),
              // Navigation Buttons (Only needed for Steps 0 and 1, Step 2 has its own buttons in SummaryStep)
              if (currentStep < 2)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (currentStep > 0)
                        TextButton(
                          onPressed: () {
                            ref.read(currentStepProvider.notifier).state--;
                          },
                          child: const Text('Voltar'),
                        ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: canProceed
                            ? () {
                                ref.read(currentStepProvider.notifier).state++;
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: Text(currentStep == 1 ? 'Revisar' : 'Próximo'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // RIGHT COL: Real-time Summary (Flex 2)
        Container(width: 1, color: Colors.grey[200]),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.grey[50], // Slightly different background
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pré-visualização',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SummaryCard(
                    client: client,
                    items: items,
                    total: total,
                    // No edit callbacks here as we are already editing on the left
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    int currentStep,
    bool canProceed,
  ) {
    return Column(
      children: [
        // Stepper indicator
        _buildStepIndicator(context, currentStep),

        // Step content
        Expanded(
          child: IndexedStack(
            index: currentStep,
            children: const [ClientStep(), ServiceStep(), SummaryStep()],
          ),
        ),

        // Navigation buttons
        if (currentStep < 2)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(currentStepProvider.notifier).state--;
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Voltar'),
                      ),
                    ),
                  if (currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canProceed
                          ? () {
                              ref.read(currentStepProvider.notifier).state++;
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(currentStep == 1 ? 'Revisar' : 'Próximo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepIndicator(BuildContext context, int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepItem(
            context,
            stepNumber: 1,
            label: 'Cliente',
            icon: Icons.person,
            isActive: currentStep == 0,
            isCompleted: currentStep > 0,
          ),
          _buildStepConnector(context, isCompleted: currentStep > 0),
          _buildStepItem(
            context,
            stepNumber: 2,
            label: 'Serviços',
            icon: Icons.build,
            isActive: currentStep == 1,
            isCompleted: currentStep > 1,
          ),
          _buildStepConnector(context, isCompleted: currentStep > 1),
          _buildStepItem(
            context,
            stepNumber: 3,
            label: 'Resumo',
            icon: Icons.description,
            isActive: currentStep == 2,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context, {
    required int stepNumber,
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isCompleted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isCompleted || isActive ? colorScheme.primary : Colors.grey;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted || isActive
                  ? colorScheme.primary
                  : Colors.grey[300],
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(
    BuildContext context, {
    required bool isCompleted,
  }) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300],
      ),
    );
  }

  void _showExitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Orçamento?'),
        content: const Text(
          'Tem certeza que deseja sair? Todas as informações serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              resetWizard(ref);
              Navigator.pop(context);
              context.go('/dashboard');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
