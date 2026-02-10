import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/subscription_badge.dart';
import '../../widgets/constrained_layout.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orça+'),
        centerTitle: false,
        actions: [
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox();
              return ref
                  .watch(subscriptionProvider(user.uid))
                  .when(
                    data: (subscription) {
                      if (subscription == null) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SubscriptionBadge(tier: subscription.tier),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          return ConstrainedLayout(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 400 ? 16 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${user.name.split(' ').first}! 👋',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O que deseja fazer hoje?',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    AnimationLimiter(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Optimized Responsive Grid Logic
                          final width = constraints.maxWidth;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: width < 600 ? 2 : 4,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: width < 360 ? 1.0 : 1.1,
                                ),
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              final cards = [
                                DashboardCard(
                                  title: 'Novo Orçamento',
                                  icon: Icons.add_circle_outline,
                                  color: AppTheme.primaryBlue,
                                  onTap: () => context.push('/budget/new'),
                                ),
                                DashboardCard(
                                  title: 'Orçamentos',
                                  icon: Icons.folder_outlined,
                                  color: AppTheme.secondaryGreen,
                                  onTap: () => context.go('/budgets'),
                                ),
                                DashboardCard(
                                  title: 'Serviços',
                                  icon: Icons.electric_bolt_outlined,
                                  color: AppTheme.warningColor,
                                  onTap: () => context.go('/services'),
                                ),
                                // Reports card (Premium only)
                                Consumer(
                                  builder: (context, ref, child) {
                                    final subscription = ref
                                        .watch(subscriptionProvider(user.uid))
                                        .value;

                                    return DashboardCard(
                                      title: 'Relatórios',
                                      icon: Icons.assessment_outlined,
                                      color: Colors.purple[700]!,
                                      onTap: () => context.push('/reports'),
                                      badge:
                                          subscription?.tier.name == 'premium'
                                          ? null
                                          : '⭐',
                                    );
                                  },
                                ),
                                DashboardCard(
                                  title: 'Configurações',
                                  icon: Icons.settings_outlined,
                                  color: Colors.grey[700]!,
                                  onTap: () => context.go('/settings'),
                                ),
                              ];

                              return AnimationConfiguration.staggeredGrid(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                columnCount: 2, // Approximate for animation
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(child: cards[index]),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
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
