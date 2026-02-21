import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orcamais/screens/budget/steps/client_step.dart';
import 'package:orcamais/screens/budget/steps/service_step.dart';
import 'package:orcamais/screens/budget/steps/summary_step.dart';
import '../../../providers/budget_wizard_providers.dart';
import '../../../widgets/constrained_layout.dart';

class ProNewBudgetScreen extends ConsumerWidget {
  const ProNewBudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pro users get a streamlined, dense experience
    final currentStep = ref.watch(currentStepProvider);
    final canProceed = ref.watch(canProceedProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'NOVO ORÇAMENTO',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.0,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => _showExitDialog(context, ref),
        ),
      ),
      body: ConstrainedLayout(
        child: Column(
          children: [
            // Pro Progress Indicator (Linear and Minimal)
            LinearProgressIndicator(
              value: (currentStep + 1) / 3,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              minHeight: 2,
            ),

            // Step Label
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStepName(currentStep).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'PASSO ${currentStep + 1}/3',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: IndexedStack(
                index: currentStep,
                children: const [
                  // We reuse the steps but wrap them to force dense theme if possible,
                  // or just rely on the global Pro theme.
                  ClientStep(),
                  ServiceStep(),
                  SummaryStep(),
                ],
              ),
            ),

            // Pro Action Bar
            if (currentStep < 2)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      if (currentStep > 0)
                        TextButton(
                          onPressed: () {
                            ref.read(currentStepProvider.notifier).state--;
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                          ),
                          child: const Text('VOLTAR'),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: canProceed
                            ? () {
                                ref.read(currentStepProvider.notifier).state++;
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          elevation: 0,
                        ),
                        child: Text(currentStep == 1 ? 'REVISAR' : 'PRÓXIMO'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStepName(int step) {
    switch (step) {
      case 0:
        return 'Definir Cliente';
      case 1:
        return 'Selecionar Serviços';
      case 2:
        return 'Revisão Final';
      default:
        return '';
    }
  }

  void _showExitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar rascunho?'),
        content: const Text(
          'Se sair agora, os dados preenchidos serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar Editando'),
          ),
          TextButton(
            onPressed: () {
              ref.read(currentStepProvider.notifier).state = 0;
              ref.read(selectedClientProvider.notifier).state = null;
              ref.read(selectedServicesProvider.notifier).state = [];
              Navigator.pop(context);
              context.go('/dashboard');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }
}
