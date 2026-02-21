import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/subscription_viewmodel.dart';
import '../../../viewmodels/budget_viewmodel.dart';
import '../../../widgets/home/home_header.dart';
import '../../../widgets/home/primary_action_button.dart';
import '../../../widgets/home/recent_budget_card.dart';
import '../../../widgets/home/quick_action_card.dart';
import '../../../core/theme/app_theme.dart';

class FreeDashboardScreen extends ConsumerWidget {
  const FreeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          final subscriptionAsync = ref.watch(subscriptionProvider(user.uid));
          final budgetsAsync = ref.watch(budgetsProvider(user.uid));

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section
                HomeHeader(user: user, subscription: subscriptionAsync.value),

                // 2. Main Content Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Action: New Budget
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: PrimaryActionButton(
                          onTap: () => context.push('/budget/new'),
                        ),
                      ),

                      // 3. Quick Actions Grid
                      const SizedBox(height: 8),
                      Text(
                        'Acesso Rápido',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimationLimiter(
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 375),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              horizontalOffset: 50.0,
                              child: FadeInAnimation(child: widget),
                            ),
                            children: [
                              QuickActionCard(
                                title: 'Clientes',
                                icon: Icons.people_outline,
                                color: AppTheme.primaryBlue,
                                onTap: () => context.go('/clients'),
                              ),
                              QuickActionCard(
                                title: 'Serviços',
                                icon: Icons.electric_bolt_outlined,
                                color: AppTheme.warningColor,
                                onTap: () => context.go('/services'),
                              ),
                              QuickActionCard(
                                title: 'Relatórios',
                                icon: Icons.assessment_outlined,
                                color: Colors.purple,
                                onTap: () => context.push('/reports'),
                                badge: 'PREMIUM',
                              ),
                              QuickActionCard(
                                title: 'Configurações',
                                icon: Icons.settings_outlined,
                                color: Colors.grey,
                                onTap: () => context.go('/settings'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. Recent Budgets Section
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Orçamentos Recentes',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.go('/budgets'),
                            child: const Text('Ver todos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: budgetsAsync.when(
                          data: (budgets) {
                            if (budgets.isEmpty) {
                              return Center(
                                child: Text(
                                  'Nenhum orçamento ainda.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              );
                            }
                            // Take last 5
                            final recentBudgets = budgets.take(5).toList();
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: recentBudgets.length,
                              itemBuilder: (context, index) {
                                final budget = recentBudgets[index];
                                return RecentBudgetCard(
                                  budget: budget,
                                  onTap: () => context.push(
                                    '/budget/preview',
                                    extra: budget,
                                  ),
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) =>
                              Center(child: Text('Erro ao carregar')),
                        ),
                      ),

                      // Bottom padding for scrolling
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }
}
