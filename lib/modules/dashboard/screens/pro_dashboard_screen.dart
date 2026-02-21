import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/budget_viewmodel.dart';
import '../../../models/budget_model.dart';
import '../../../core/theme/app_theme.dart';

class ProDashboardScreen extends ConsumerWidget {
  const ProDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final budgetsAsync = ref.watch(budgetsProvider(userAsync.value?.uid ?? ''));

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pro Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visão Geral',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM',
                          'pt_BR',
                        ).format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: user.photoUrl == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0] : 'U',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Quick Actions Bar (Dense)
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _ProActionButton(
                      label: 'Novo Orçamento',
                      icon: Icons.add,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => context.push('/budget/new'),
                      isPrimary: true,
                    ),
                    const SizedBox(width: 8),
                    _ProActionButton(
                      label: 'Clientes',
                      icon: Icons.people_alt_outlined,
                      onTap: () => context.go('/clients'),
                    ),
                    const SizedBox(width: 8),
                    _ProActionButton(
                      label: 'Serviços',
                      icon: Icons.inventory_2_outlined,
                      onTap: () => context.go('/services'),
                    ),
                    const SizedBox(width: 8),
                    _ProActionButton(
                      label: 'Relatórios',
                      icon: Icons.bar_chart_outlined,
                      onTap: () => context.push('/reports'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. Status Overview (Metrics styled for Pro)
              // We can fetch metrics from dashboard_viewmodel later, for now placeholders/reuse
              _ProSectionTitle(title: 'Resumo do Mês'),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _ProMetricCard(
                      label: 'Em Aberto',
                      value: '4',
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _ProMetricCard(
                      label: 'Aprovados',
                      value: '12',
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _ProMetricCard(
                      label: 'Faturamento',
                      value: 'R\$ 14.5k',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 4. Recent Budgets (Dense List)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ProSectionTitle(title: 'Orçamentos Recentes'),
                  TextButton(
                    onPressed: () => context.go('/budgets'),
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              budgetsAsync.when(
                data: (budgets) {
                  if (budgets.isEmpty) return const Text('Nenhum orçamento.');
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: budgets.take(5).length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      itemBuilder: (context, index) {
                        final budget = budgets[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            budget.clientName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(budget.createdAt),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                NumberFormat.simpleCurrency(
                                  locale: 'pt_BR',
                                ).format(budget.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusBadge(status: budget.status),
                            ],
                          ),
                          onTap: () =>
                              context.push('/budget/preview', extra: budget),
                        );
                      },
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erro: $e'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erro ao carregar usuário')),
    );
  }
}

class _ProSectionTitle extends StatelessWidget {
  final String title;
  const _ProSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}

class _ProActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool isPrimary;

  const _ProActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isPrimary
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final fgColor = isPrimary
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      elevation: isPrimary ? 1 : 0,
      shape: isPrimary
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              side: BorderSide(color: theme.dividerColor),
            ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fgColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BudgetStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BudgetStatus.accepted:
      case BudgetStatus.paid:
        color = Colors.green;
        break;
      case BudgetStatus.pending:
        color = Colors.orange;
        break;
      case BudgetStatus.rejected:
      case BudgetStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
