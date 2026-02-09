import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../core/utils/formatters.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final ValueChanged<int>? onQuantityChanged;
  final bool showQuantityControls;

  const ServiceCard({
    super.key,
    required this.service,
    this.quantity = 0,
    this.onAdd,
    this.onRemove,
    this.onQuantityChanged,
    this.showQuantityControls = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = quantity > 0;

    return Card(
      elevation: isSelected ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (service.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatCurrency(service.unitPrice),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),

                // Add/Remove or Quantity controls
                if (showQuantityControls && isSelected)
                  _buildQuantityControls(context)
                else if (onAdd != null)
                  IconButton(
                    onPressed: isSelected ? onRemove : onAdd,
                    icon: Icon(
                      isSelected ? Icons.remove_circle : Icons.add_circle,
                      color: isSelected
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),

            // Subtotal when selected
            if (isSelected && showQuantityControls) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    Formatters.formatCurrency(service.unitPrice * quantity),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: quantity > 1
              ? () => onQuantityChanged?.call(quantity - 1)
              : onRemove,
          icon: Icon(
            quantity > 1 ? Icons.remove : Icons.delete,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            quantity.toString(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => onQuantityChanged?.call(quantity + 1),
          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }
}
