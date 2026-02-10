import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../models/client_model.dart';
import '../../models/budget_model.dart';
import '../../viewmodels/client_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../core/utils/formatters.dart';

class ClientDetailsScreen extends ConsumerWidget {
  final String clientId;
  final ClientModel? initialClient;

  const ClientDetailsScreen({
    super.key,
    required this.clientId,
    this.initialClient,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsStreamProvider);
    final budgetsAsync = ref.watch(clientBudgetsStreamProvider(clientId));

    return clientsAsync.when(
      data: (clients) {
        final client = clients.firstWhere(
          (c) => c.id == clientId,
          orElse: () =>
              initialClient ??
              ClientModel(
                id: clientId,
                userId: '',
                name: 'Cliente não encontrado',
                phone: '',
                createdAt: DateTime.now(),
              ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(client.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editClient(context, client),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClientInfoCard(context, client, budgetsAsync.value ?? []),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Histórico de Orçamentos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                budgetsAsync.when(
                  data: (budgets) => _buildBudgetsList(context, budgets, ref),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Erro ao carregar orçamentos: $err'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro: $err'))),
    );
  }

  Widget _buildClientInfoCard(
    BuildContext context,
    ClientModel client,
    List<BudgetModel> budgets,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.total);
    final paidCount = budgets
        .where((b) => b.status == BudgetStatus.paid)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      client.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            client.phone,
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      if (client.address != null &&
                          client.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                client.address!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Total Acumulado',
                  NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$',
                  ).format(totalSpent),
                  colorScheme.primary,
                ),
                _buildStatItem(
                  context,
                  'Orçamentos',
                  budgets.length.toString(),
                  colorScheme.secondary,
                ),
                _buildStatItem(
                  context,
                  'Pagos',
                  paidCount.toString(),
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _callClient(client.phone),
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text('Ligar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _whatsappClient(client.phone),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(
                        0xFF25D366,
                      ).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF25D366),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBudgetsList(
    BuildContext context,
    List<BudgetModel> budgets,
    WidgetRef ref,
  ) {
    if (budgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Nenhum orçamento encontrado.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final theme = Theme.of(context);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusColor(budget.status).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIconData(budget.status),
                color: _getStatusColor(budget.status),
                size: 20,
              ),
            ),
            title: Text(
              'Orçamento #${Formatters.formatBudgetNumber(budget.budgetNumber)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy • HH:mm').format(budget.createdAt),
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$',
                  ).format(budget.total),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _getStatusBadge(budget.status),
              ],
            ),
            onTap: () => _showBudgetActions(context, budget, ref),
          ),
        );
      },
    );
  }

  IconData _getStatusIconData(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.paid:
        return Icons.check_circle_outline;
      case BudgetStatus.pending:
        return Icons.access_time;
      case BudgetStatus.cancelled:
        return Icons.cancel_outlined;
      case BudgetStatus.accepted:
        return Icons.thumb_up_outlined;
      case BudgetStatus.rejected:
        return Icons.thumb_down_outlined;
    }
  }

  Color _getStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.paid:
        return Colors.green;
      case BudgetStatus.pending:
        return Colors.orange;
      case BudgetStatus.cancelled:
        return Colors.red;
      case BudgetStatus.accepted:
        return Colors.blue;
      case BudgetStatus.rejected:
        return Colors.grey;
    }
  }

  Widget _getStatusBadge(BudgetStatus status) {
    Color color;
    switch (status) {
      case BudgetStatus.paid:
        color = Colors.green;
        break;
      case BudgetStatus.pending:
        color = Colors.orange;
        break;
      case BudgetStatus.cancelled:
        color = Colors.red;
        break;
      case BudgetStatus.accepted:
        color = Colors.blue;
        break;
      case BudgetStatus.rejected:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showBudgetActions(
    BuildContext context,
    BudgetModel budget,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Ver Orçamento'),
            onTap: () {
              Navigator.pop(context);
              // Implementar navegação para detalhe do orçamento se existir
            },
          ),
          if (budget.status != BudgetStatus.paid)
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.green),
              title: const Text('Marcar como Pago'),
              onTap: () {
                ref
                    .read(budgetViewModelProvider.notifier)
                    .updateBudgetStatus(
                      budget.id,
                      BudgetStatus.paid,
                      budget: budget,
                    );
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Cancelar Orçamento'),
            onTap: () {
              ref
                  .read(budgetViewModelProvider.notifier)
                  .updateBudgetStatus(budget.id, BudgetStatus.cancelled);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _editClient(BuildContext context, ClientModel client) {
    // Redirecionar para tela de edição
    context.push('/clients/edit/${client.id}', extra: client);
  }

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsappClient(String phone) async {
    final uri = Uri.parse(
      'https://wa.me/55${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
