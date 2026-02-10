import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../models/client_model.dart';
import '../../models/budget_model.dart';
import '../../viewmodels/client_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';

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
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.total);
    final paidCount = budgets
        .where((b) => b.status == BudgetStatus.paid)
        .length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    client.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.phone, style: const TextStyle(fontSize: 16)),
                      if (client.address != null && client.address!.isNotEmpty)
                        Text(
                          client.address!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Acumulado',
                  NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$',
                  ).format(totalSpent),
                ),
                _buildStatItem('Orçamentos', budgets.length.toString()),
                _buildStatItem('Pagos', paidCount.toString()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callClient(client.phone),
                    icon: const Icon(Icons.phone),
                    label: const Text('Ligar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _whatsappClient(client.phone),
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        return ListTile(
          leading: _getStatusIcon(budget.status),
          title: Text('Orçamento #${budget.budgetNumber}'),
          subtitle: Text(
            DateFormat('dd/MM/yyyy HH:mm').format(budget.createdAt),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _getStatusBadge(budget.status),
            ],
          ),
          onTap: () => _showBudgetActions(context, budget, ref),
        );
      },
    );
  }

  Widget _getStatusIcon(BudgetStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case BudgetStatus.paid:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case BudgetStatus.pending:
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case BudgetStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case BudgetStatus.accepted:
        icon = Icons.thumb_up;
        color = Colors.blue;
        break;
      case BudgetStatus.rejected:
        icon = Icons.thumb_down;
        color = Colors.grey;
        break;
    }

    return Icon(icon, color: color);
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
