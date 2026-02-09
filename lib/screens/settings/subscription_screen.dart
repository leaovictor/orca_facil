import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/subscription_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../widgets/custom_button.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  Future<void> _launchStripeCheckout(String userId) async {
    final Uri url = Uri.parse(
      '${AppConstants.stripeProMonthlyUrl}?client_reference_id=$userId',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final subscriptionAsync = user != null
        ? ref.watch(subscriptionProvider(user.uid))
        : const AsyncValue<SubscriptionModel?>.loading();

    return Scaffold(
      appBar: AppBar(title: const Text('Assinatura Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Escolha o plano ideal para você',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Aumente seus limites e profissionalize seus orçamentos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPlanCard(
              context,
              title: 'Plano Gratuito',
              price: 'R\$ 0,00',
              features: [
                'Até 5 orçamentos por mês',
                'Orçamentos simples',
                'Marca d\'água nos PDFs',
              ],
              isCurrent: subscriptionAsync.value?.tier == SubscriptionTier.free,
              onPressed: () {}, // Already active
              isPro: false,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              title: 'Plano Pro',
              price: 'R\$ 19,90 / mês',
              features: [
                'Orçamentos ILIMITADOS',
                'Sem marca d\'água',
                'Prioridade no suporte',
                'Acesso a novos recursos',
              ],
              isCurrent: subscriptionAsync.value?.tier == SubscriptionTier.pro,
              onPressed: () => _launchStripeCheckout(user!.uid),
              isPro: true,
              isRecommended: true,
            ),
            const SizedBox(height: 32),
            const Text(
              'Dúvidas sobre o pagamento?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'O pagamento é processado de forma segura pelo Stripe. Você pode cancelar a qualquer momento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required List<String> features,
    required bool isCurrent,
    required VoidCallback onPressed,
    required bool isPro,
    bool isRecommended = false,
  }) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Card(
          elevation: isRecommended ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isRecommended
                ? const BorderSide(color: AppTheme.primaryBlue, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isRecommended) const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isRecommended ? AppTheme.primaryBlue : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: isRecommended
                              ? AppTheme.primaryBlue
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isPro
                          ? AppTheme.successColor.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check,
                          color: isPro ? AppTheme.successColor : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Plano Atual',
                          style: TextStyle(
                            color: isPro ? AppTheme.successColor : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  CustomButton(
                    text: isPro ? 'Assinar Agora' : 'Downgrade',
                    onPressed: onPressed,
                    backgroundColor: isPro ? AppTheme.primaryBlue : Colors.grey,
                    textColor: Colors.white,
                  ),
              ],
            ),
          ),
        ),
        if (isRecommended)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MAIS POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
