import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/subscription_badge.dart';
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

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${user.name.split(' ').first}! 👋',
                    style: Theme.of(context).textTheme.displaySmall,
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
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
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
                            onTap: () => context.push('/budgets'),
                          ),
                          DashboardCard(
                            title: 'Serviços',
                            icon: Icons.electric_bolt_outlined,
                            color: AppTheme.warningColor,
                            onTap: () => context.push('/services'),
                          ),
                          DashboardCard(
                            title: 'Configurações',
                            icon: Icons.settings_outlined,
                            color: Colors.grey[700]!,
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
