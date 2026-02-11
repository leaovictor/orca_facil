import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/premium_buttons.dart';
import '../../widgets/premium_cards.dart';

/// Premium Paywall Screen
///
/// Tela de planos FREE vs PRO com design premium
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Escolha seu plano'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceMd + 4), // 20px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Crie orçamentos\nilimitados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              const Text(
                'Escolha o plano ideal para o seu negócio',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),

              const SizedBox(height: AppTheme.spaceXl + 8), // 40px
              // FREE Plan Card
              PremiumCard(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FREE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.slate200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Plano Atual',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'R\$ 0',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(width: AppTheme.spaceSm),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '/mês',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    _buildFeature('✓', 'Até 5 orçamentos/mês', true),
                    _buildFeature('✓', 'PDF básico', true),
                    _buildFeature('✗', 'QR Code PIX', false),
                    _buildFeature('✗', 'Histórico completo', false),
                    _buildFeature('✗', 'Orçamentos ilimitados', false),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spaceMd + 4), // 20px
              // PRO Plan Card (Highlighted)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.shadowPrimary,
                ),
                child: PremiumCard(
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 24),
                              SizedBox(width: AppTheme.spaceSm),
                              Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Mais Popular',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceSm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'R\$ 29,90',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSm),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '/mês',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceLg),
                      _buildFeature(
                        '✓',
                        'Orçamentos ilimitados',
                        true,
                        isLight: true,
                      ),
                      _buildFeature(
                        '✓',
                        'PDF profissional',
                        true,
                        isLight: true,
                      ),
                      _buildFeature(
                        '✓',
                        'QR Code PIX automático',
                        true,
                        isLight: true,
                      ),
                      _buildFeature(
                        '✓',
                        'Histórico completo',
                        true,
                        isLight: true,
                      ),
                      _buildFeature(
                        '✓',
                        'Suporte prioritário',
                        true,
                        isLight: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceXl),

              // CTA Button
              PrimaryButton(
                text: 'Assinar PRO agora',
                icon: Icons.star,
                onPressed: () {
                  // TODO: Implementar lógica de assinatura
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Integração com pagamento em breve!'),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                },
              ),

              const SizedBox(height: AppTheme.spaceMd),

              SecondaryButton(
                text: 'Continuar com FREE',
                onPressed: () => context.pop(),
              ),

              const SizedBox(height: AppTheme.spaceLg),

              // Note
              Text(
                'Cancele quando quiser. Garantia de 7 dias.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(
    String icon,
    String text,
    bool included, {
    bool isLight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4), // 12px
      child: Row(
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 18,
              color: isLight
                  ? (included
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5))
                  : (included ? AppTheme.successGreen : AppTheme.textMuted),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isLight
                    ? (included
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6))
                    : (included ? AppTheme.textPrimary : AppTheme.textMuted),
                decoration: included ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
