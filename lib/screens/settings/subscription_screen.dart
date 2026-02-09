import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/subscription_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../widgets/custom_button.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoadingPortal = false;

  Future<void> _launchStripeCheckout(String userId, String url) async {
    final Uri uri = Uri.parse('$url?client_reference_id=$userId');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir pagamento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openCustomerPortal() async {
    setState(() => _isLoadingPortal = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createStripePortalSession');
      final result = await callable.call();

      final url = result.data['url'] as String;
      final Uri uri = Uri.parse(url);

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch portal');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir portal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPortal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final subscriptionAsync = user != null
        ? ref.watch(subscriptionProvider(user.uid))
        : const AsyncValue<SubscriptionModel?>.loading();

    final currentTier = subscriptionAsync.value?.tier ?? SubscriptionTier.free;
    final hasActiveSubscription = subscriptionAsync.value?.isActive ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Planos e Assinatura')),
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
              'Desbloqueie todo o potencial do Orça+',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            // Manage subscription button (if has active subscription)
            if (hasActiveSubscription &&
                currentTier != SubscriptionTier.free) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Você tem uma assinatura ativa',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: _isLoadingPortal
                            ? 'Carregando...'
                            : 'Gerenciar Assinatura',
                        onPressed: _isLoadingPortal
                            ? () {}
                            : _openCustomerPortal,
                        backgroundColor: Colors.blue,
                        textColor: Colors.white,
                        icon: _isLoadingPortal
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.manage_accounts,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Atualize, cancele ou gerencie seu pagamento',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Free Plan
            _buildPlanCard(
              context,
              title: 'Gratuito',
              price: 'R\$ 0,00',
              features: const [
                'Até 5 orçamentos por mês',
                'Orçamentos básicos',
                'Marca d\'água nos PDFs',
                'Suporte por email',
              ],
              isCurrent: currentTier == SubscriptionTier.free,
              onPressed: () {},
              tier: SubscriptionTier.free,
            ),

            const SizedBox(height: 16),

            // Pro Plan
            _buildPlanCard(
              context,
              title: 'Pro',
              price: 'R\$ 19,90 / mês',
              features: const [
                '✨ Orçamentos ILIMITADOS',
                '✨ Sem marca d\'água',
                '✨ Integração WhatsApp',
                '✨ Suporte prioritário',
              ],
              isCurrent: currentTier == SubscriptionTier.pro,
              onPressed: currentTier == SubscriptionTier.pro
                  ? () {}
                  : () => _launchStripeCheckout(
                      user!.uid,
                      AppConstants.stripeProMonthlyUrl,
                    ),
              tier: SubscriptionTier.pro,
              isRecommended: true,
            ),

            const SizedBox(height: 16),

            // Premium Plan
            _buildPlanCard(
              context,
              title: 'Premium',
              price: 'R\$ 39,90 / mês',
              features: const [
                '⭐ Tudo do Pro +',
                '⭐ Dashboard Financeiro',
                '⭐ Relatórios Avançados (4 tipos)',
                '⭐ Exportação para Excel',
                '⭐ Análises e métricas',
              ],
              isCurrent: currentTier == SubscriptionTier.premium,
              onPressed: currentTier == SubscriptionTier.premium
                  ? () {}
                  : () => _launchStripeCheckout(
                      user!.uid,
                      AppConstants.stripePremiumMonthlyUrl,
                    ),
              tier: SubscriptionTier.premium,
            ),

            const SizedBox(height: 32),
            const Text(
              'Dúvidas sobre o pagamento?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pagamento 100% seguro processado pelo Stripe. Cancele a qualquer momento sem taxas.',
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
    required SubscriptionTier tier,
    bool isRecommended = false,
  }) {
    final theme = Theme.of(context);
    final isPro = tier == SubscriptionTier.pro;
    final isPremium = tier == SubscriptionTier.premium;

    Color getBorderColor() {
      if (isPremium) return Colors.purple;
      if (isPro) return AppTheme.primaryBlue;
      return Colors.grey.shade300;
    }

    Color getButtonColor() {
      if (isPremium) return Colors.purple;
      if (isPro) return AppTheme.primaryBlue;
      return Colors.grey;
    }

    return Stack(
      children: [
        Card(
          elevation: isRecommended ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: getBorderColor(),
              width: isRecommended || isPremium ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isRecommended || isPremium) const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPremium
                        ? Colors.purple
                        : isRecommended
                        ? AppTheme.primaryBlue
                        : null,
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
                          color: isPremium
                              ? Colors.purple
                              : isRecommended
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
                      color: getButtonColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, color: getButtonColor()),
                        const SizedBox(width: 8),
                        Text(
                          'Plano Atual',
                          style: TextStyle(
                            color: getButtonColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  CustomButton(
                    text: tier == SubscriptionTier.free
                        ? 'Plano Gratuito'
                        : 'Assinar Agora',
                    onPressed: tier == SubscriptionTier.free
                        ? () {}
                        : onPressed,
                    backgroundColor: getButtonColor(),
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
        if (isPremium && !isRecommended)
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
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'RECURSOS AVANÇADOS',
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
