import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../models/budget_model.dart';
import '../../../core/utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  final ClientModel? client;
  final List<BudgetItem> items;
  final double total;
  final VoidCallback? onEditClient;
  final VoidCallback? onEditServices;

  const SummaryCard({
    super.key,
    required this.client,
    required this.items,
    required this.total,
    this.onEditClient,
    this.onEditServices,
  });

  @override
  Widget build(BuildContext context) {
    if (client == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Nenhum dado preenchido ainda')),
        ),
      );
    }

    return Column(
      children: [
        // Client info card
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cliente',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (onEditClient != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEditClient,
                        tooltip: 'Editar Cliente',
                      ),
                  ],
                ),
                const Divider(),
                _buildInfoRow('Nome', client!.name),
                if (client!.phone.isNotEmpty)
                  _buildInfoRow(
                    'Telefone',
                    Formatters.formatPhone(client!.phone),
                  ),
                if (client!.address != null && client!.address!.isNotEmpty)
                  _buildInfoRow('Endereço', client!.address!),
              ],
            ),
          ),
        ),

        // Services card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.build_circle_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Serviços',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (onEditServices != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEditServices,
                        tooltip: 'Editar Serviços',
                      ),
                  ],
                ),
                const Divider(),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Nenhum serviço adicionado'),
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.serviceName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (item.serviceDescription.isNotEmpty)
                                  Text(
                                    item.serviceDescription,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text(
                                  '${item.quantity}x ${Formatters.formatCurrency(item.unitPrice)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(item.total),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(total),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
