import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../widgets/premium_cards.dart';
import '../../widgets/premium_badges.dart';
import '../../core/theme/app_theme.dart';

/// Premium Dashboard Screen
///
/// Dashboard redesenhado seguindo o design system premium
class PremiumDashboardScreen extends ConsumerWidget {
  const PremiumDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          final subscriptionAsync = ref.watch(subscriptionProvider(user.uid));
          final budgetsAsync = ref.watch(budgetsProvider(user.uid));

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd + 4), // 20px
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Greeting + Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, ${user.name.split(' ').first}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            Text(
                              'Vamos criar orçamentos profissionais!',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        subscriptionAsync.when(
                          data: (subscription) => PlanBadge(
                            isPro: subscription?.tier.name == 'pro',
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (err, stack) => const SizedBox.shrink(),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.spaceLg + 8), // 32px
                    // Hero CTA: Criar Novo Orçamento
                    CTACard(
                      title: 'Criar novo orçamento',
                      subtitle: 'Rápido, fácil, profissional',
                      icon: Icons.add_circle_outline_rounded,
                      onTap: () => context.push('/budget/new'),
                    ),

                    const SizedBox(height: AppTheme.spaceLg),

                    // Quick Access Cards
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Histórico',
                            value: '',
                            icon: Icons.history_rounded,
                            iconColor: AppTheme.primaryBlue,
                            onTap: () => context.go('/budgets'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMd),
                        Expanded(
                          child: StatsCard(
                            title: 'Serviços',
                            value: '',
                            icon: Icons.build_rounded,
                            iconColor: AppTheme.warningColor,
                            onTap: () => context.go('/services'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: AppTheme.spaceMd),

                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Perfil',
                            value: '',
                            icon: Icons.person_rounded,
                            iconColor: AppTheme.textSecondary,
                            onTap: () => context.go('/settings'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.spaceLg + 8), // 32px
                    // Usage Indicator (for FREE users)
                    subscriptionAsync.when(
                      data: (subscription) {
                        if (subscription == null) {
                          return const SizedBox.shrink();
                        }

                        final isFree = subscription.tier.name == 'free';
                        if (!isFree) return const SizedBox.shrink();

                        final budgetCount = subscription.budgetCount;
                        final limit = 5;
                        final percentage = (budgetCount / limit).clamp(
                          0.0,
                          1.0,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$budgetCount/$limit orçamentos este mês',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (budgetCount >= limit - 2)
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/subscription'),
                                    child: const Text(
                                      'Fazer upgrade',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: AppTheme.slate200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  budgetCount >= limit - 1
                                      ? AppTheme.warningColor
                                      : AppTheme.primaryBlue,
                                ),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceLg),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),

                    // Recent Budgets Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Orçamentos Recentes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/budgets'),
                          child: const Text('Ver todos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),

                    budgetsAsync.when(
                      data: (budgets) {
                        if (budgets.isEmpty) {
                          return PremiumCard(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppTheme.spaceLg),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 64,
                                      color: AppTheme.slate200,
                                    ),
                                    const SizedBox(height: AppTheme.spaceMd),
                                    const Text(
                                      'Nenhum orçamento ainda',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceXs),
                                    Text(
                                      'Crie seu primeiro orçamento profissional',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final recentBudgets = budgets.take(3).toList();
                        return Column(
                          children: recentBudgets.map((budget) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spaceSm + 4, // 12px
                              ),
                              child: PremiumCard(
                                onTap: () => context.push(
                                  '/budget/preview',
                                  extra: budget,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppTheme.spaceMd,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMd,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.description_rounded,
                                        color: AppTheme.primaryBlue,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spaceMd),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            budget.clientName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: AppTheme.spaceXs,
                                          ),
                                          Text(
                                            budget.items.isNotEmpty
                                                ? budget.items.first.serviceName
                                                : 'Sem itens',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'R\$ ${budget.total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.successGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spaceLg),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => const PremiumCard(
                        child: Center(
                          child: Text('Erro ao carregar orçamentos'),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.space2xl), // Bottom padding
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }
}
