import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/subscription_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';

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
      // Note: Ideally this should be a region-specific call if needed
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
      backgroundColor: Colors.grey[50], // Professional background
      appBar: AppBar(
        title: Text(
          'PLANOS & ASSINATURA',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.0,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Text(
              'Escolha a Potência do seu Negócio',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Do básico ao avançado, temos o plano perfeito para você crescer.',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            if (hasActiveSubscription &&
                currentTier != SubscriptionTier.free) ...[
              const SizedBox(height: 32),
              _buildActiveSubscriptionCard(currentTier),
            ],

            const SizedBox(height: 40),

            // Plan Cards
            _buildPlanCard(
              context,
              tier: SubscriptionTier.free,
              title: 'Gratuito',
              price: 'R\$ 0,00',
              description: 'Para quem está começando',
              features: [
                'Até 5 orçamentos/mês',
                'Orçamentos PDF básicos',
                'Marca d\'água Orça+',
                'Cadastro simples de clientes',
              ],
              isCurrent: currentTier == SubscriptionTier.free,
              onPressed: () {},
            ),

            const SizedBox(height: 24),

            _buildPlanCard(
              context,
              tier: SubscriptionTier.pro,
              title: 'Pro',
              price: 'R\$ 19,90',
              period: '/mês',
              description: 'Para profissionais autônomos',
              features: [
                'Orçamentos ILIMITADOS',
                'Sem marca d\'água',
                'Integração WhatsApp',
                'Modelos de orçamento',
                'Suporte prioritário',
              ],
              isCurrent: currentTier == SubscriptionTier.pro,
              isRecommended: true,
              onPressed: currentTier == SubscriptionTier.pro
                  ? () {}
                  : () => _launchStripeCheckout(
                      user!.uid,
                      AppConstants.stripeProMonthlyUrl,
                    ),
            ),

            const SizedBox(height: 24),

            _buildPlanCard(
              context,
              tier: SubscriptionTier.premium,
              title: 'Premium',
              price: 'R\$ 39,90',
              period: '/mês',
              description: 'Para pequenas empresas',
              features: [
                'Tudo do Pro +',
                'Dashboard Financeiro',
                'Análise de Lucro e Margem',
                'Relatórios Avançados (PDF/Excel)',
                'CRM de Clientes',
                'Múltiplos usuários (em breve)',
              ],
              isCurrent: currentTier == SubscriptionTier.premium,
              isPremium: true,
              onPressed: currentTier == SubscriptionTier.premium
                  ? () {}
                  : () => _launchStripeCheckout(
                      user!.uid,
                      AppConstants.stripePremiumMonthlyUrl,
                    ),
            ),

            const SizedBox(height: 40),

            Text(
              'Pagamento seguro via Stripe. Cancele quando quiser.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(SubscriptionTier tier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Seu plano ${tier == SubscriptionTier.premium ? "Premium" : "Pro"} está ativo',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoadingPortal ? null : _openCustomerPortal,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.blue[600]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoadingPortal
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Gerenciar Assinatura',
                      style: GoogleFonts.inter(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required SubscriptionTier tier,
    required String title,
    required String price,
    String period = '',
    required String description,
    required List<String> features,
    required bool isCurrent,
    required VoidCallback onPressed,
    bool isRecommended = false,
    bool isPremium = false,
  }) {
    final borderColor = isPremium
        ? Colors.purple.withOpacity(0.5)
        : isRecommended
        ? AppTheme.primaryBlue
        : Colors.grey[200]!;

    final headerColor = isPremium
        ? const Color(0xFF0F172A) // Dark Slate
        : Colors.white;

    final textColor = isPremium ? Colors.white : Colors.black87;
    final subTextColor = isPremium ? Colors.white70 : Colors.grey[600];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isRecommended || isPremium ? 2 : 1,
            ),
            boxShadow: [
              if (isRecommended || isPremium)
                BoxShadow(
                  color: isPremium
                      ? Colors.purple.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isRecommended || isPremium)
                const SizedBox(height: 20), // Space for badge
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isPremium
                            ? Colors.purpleAccent
                            : (isRecommended
                                  ? AppTheme.primaryBlue
                                  : Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price,
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (period.isNotEmpty)
                          Text(
                            period,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: subTextColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    ...features.map(
                      (feature) =>
                          _buildFeatureItem(feature, isPremium: isPremium),
                    ),
                    const SizedBox(height: 32),

                    if (isCurrent)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: (isPremium ? Colors.white : Colors.green)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'PLANO ATUAL',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: isPremium ? Colors.white : Colors.green,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPremium
                              ? Colors.purpleAccent
                              : (isRecommended
                                    ? AppTheme.primaryBlue
                                    : Colors.grey[800]),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          tier == SubscriptionTier.free
                              ? 'COMEÇAR GRÁTIS'
                              : 'ASSINAR AGORA',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isRecommended)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                transform: Matrix4.translationValues(0, -12, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'MAIS POPULAR',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        if (isPremium)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                transform: Matrix4.translationValues(0, -12, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'RECOMENDADO PARA EMPRESAS',
                  style: GoogleFonts.inter(
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

  Widget _buildFeatureItem(String text, {required bool isPremium}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check,
            color: isPremium ? Colors.purpleAccent : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isPremium ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
