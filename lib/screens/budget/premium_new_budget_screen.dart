import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/budget_wizard_providers.dart';
import 'widgets/profit_analysis_card.dart';
import 'steps/client_step.dart';
import 'steps/service_step.dart';
import 'steps/summary_step.dart';

class PremiumNewBudgetScreen extends ConsumerWidget {
  const PremiumNewBudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Premium Layout: Dark background, glass cards, side-by-side analysis
    final currentStep = ref.watch(currentStepProvider);
    final items = ref.watch(selectedServicesProvider);

    // Calculate financials
    double revenue = 0;
    double cost = 0;
    for (var item in items) {
      revenue += item.total;
      cost += (item.basePrice * item.quantity);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate
      appBar: AppBar(
        title: Text(
          'PROFIT ENGINE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _showExitDialog(context, ref),
        ),
      ),
      body: Row(
        children: [
          // Left: Wizard Steps (60%)
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  // Premium Stepper
                  _buildPremiumStepper(context, currentStep),

                  // Content
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        // Force dark theme inside this container for the steps
                        brightness: Brightness.dark,
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFF38BDF8), // Sky Blue
                          surface: Colors.transparent,
                        ),
                        textTheme: GoogleFonts.outfitTextTheme(
                          ThemeData.dark().textTheme,
                        ),
                      ),
                      child: IndexedStack(
                        index: currentStep,
                        children: const [
                          // We might need to adjust these steps to look good in dark mode
                          // If they use standard Theme.of(context), they should adapt.
                          ClientStep(),
                          ServiceStep(),
                          SummaryStep(),
                        ],
                      ),
                    ),
                  ),

                  // Navigation
                  _buildPremiumNavigation(context, ref, currentStep),
                ],
              ),
            ),
          ),

          // Right: Real-time Profit Intelligence (40%)
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  ProfitAnalysisCard(revenue: revenue, cost: cost),
                  const SizedBox(height: 16),

                  // AI Suggestions Placeholder
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.purpleAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI INSIGHTS',
                                style: GoogleFonts.outfit(
                                  color: Colors.purpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            items.isEmpty
                                ? 'Adicione serviços para receber sugestões de precificação e melhoria de margem.'
                                : '💡 A margem do serviço "Instalação" está 15% abaixo da média do mercado. Considere ajustar para R\$ 180,00.',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStepper(BuildContext context, int currentStep) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepDot(0, currentStep),
          _stepLine(),
          _stepDot(1, currentStep),
          _stepLine(),
          _stepDot(2, currentStep),
        ],
      ),
    );
  }

  Widget _stepDot(int index, int current) {
    bool active = index <= current;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF38BDF8) : Colors.white10,
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.5),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
    );
  }

  Widget _stepLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildPremiumNavigation(
    BuildContext context,
    WidgetRef ref,
    int currentStep,
  ) {
    final canProceed = ref.watch(canProceedProvider);

    if (currentStep >= 2)
      return const SizedBox.shrink(); // Summary has its own buttons

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep > 0)
            TextButton(
              onPressed: () => ref.read(currentStepProvider.notifier).state--,
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('VOLTAR'),
            )
          else
            const SizedBox(),

          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF38BDF8),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: canProceed
                  ? () => ref.read(currentStepProvider.notifier).state++
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(
                currentStep == 1 ? 'REVISAR' : 'PRÓXIMO',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Sair do Profit Engine?',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          'Seus dados não serão salvos.',
          style: GoogleFonts.outfit(color: Colors.white70),
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
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
