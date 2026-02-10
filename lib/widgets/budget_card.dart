import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../core/utils/formatters.dart';

class BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback? onWhatsApp; // Optional WhatsApp share
  final VoidCallback onDelete;
  final bool canUseWhatsApp; // Pro/Premium feature

  const BudgetCard({
    super.key,
    required this.budget,
    required this.onTap,
    required this.onShare,
    this.onWhatsApp,
    required this.onDelete,
    this.canUseWhatsApp = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orçamento #${Formatters.formatBudgetNumber(budget.budgetNumber)}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          Formatters.formatDate(budget.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Excluir',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.clientName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            Formatters.formatPhone(budget.clientPhone),
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(budget.total),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('PDF'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (canUseWhatsApp && onWhatsApp != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onWhatsApp,
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366),
                            side: const BorderSide(color: Color(0xFF25D366)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
