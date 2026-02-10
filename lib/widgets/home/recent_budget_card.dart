import 'package:flutter/material.dart';
import '../../models/budget_model.dart';
import '../../core/utils/formatters.dart';

class RecentBudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onTap;

  const RecentBudgetCard({
    super.key,
    required this.budget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determines status color
    Color statusColor;
    String statusText;

    switch (budget.status) {
      case BudgetStatus.pending:
        statusColor = Colors.grey;
        statusText = 'Pendente';
        break;
      case BudgetStatus.accepted:
        statusColor = Colors.green;
        statusText = 'Aprovado';
        break;
      case BudgetStatus.paid:
        statusColor = Colors.green[700]!;
        statusText = 'Pago';
        break;
      case BudgetStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Rejeitado';
        break;
      case BudgetStatus.cancelled:
        statusColor = Colors.grey[700]!;
        statusText = 'Cancelado';
        break;
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.formatDate(budget.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  budget.clientName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Orçamento #${Formatters.formatBudgetNumber(budget.budgetNumber)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  Formatters.formatCurrency(budget.total),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
