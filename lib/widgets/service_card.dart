import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../core/utils/formatters.dart';
import '../core/pricing/pricing_engine.dart';

class ServiceCard extends StatefulWidget {
  final ServiceModel service;
  final int quantity;
  final String difficulty;
  final String environment;
  final double distance;
  final Function(
    int quantity,
    String difficulty,
    String environment,
    double distance,
    double unitPrice,
  )?
  onChanged;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final bool showControls;

  const ServiceCard({
    super.key,
    required this.service,
    this.quantity = 0,
    this.difficulty = 'Fácil',
    this.environment = 'Sala',
    this.distance = 0,
    this.onChanged,
    this.onAdd,
    this.onRemove,
    this.showControls = false,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  late int _quantity;
  late String _difficulty;
  late String _environment;
  late double _distance;
  late double _unitPrice;

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity;
    _difficulty = widget.difficulty;
    _environment = widget.environment;
    _distance = widget.distance;
    _calculatePrice();
  }

  @override
  void didUpdateWidget(ServiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity ||
        widget.difficulty != oldWidget.difficulty ||
        widget.environment != oldWidget.environment ||
        widget.distance != oldWidget.distance) {
      setState(() {
        _quantity = widget.quantity;
        _difficulty = widget.difficulty;
        _environment = widget.environment;
        _distance = widget.distance;
        _calculatePrice();
      });
    }
  }

  void _calculatePrice() {
    _unitPrice = PricingEngine.calculateUnitPrice(
      basePrice: widget.service.unitPrice,
      difficultyMultiplier: PricingEngine.getDifficultyMultiplier(_difficulty),
      environmentMultiplier: PricingEngine.getEnvironmentMultiplier(
        _environment,
      ),
      distanceMultiplier: PricingEngine.getDistanceMultiplier(_distance),
    );
  }

  void _notifyChanges() {
    _calculatePrice();
    widget.onChanged?.call(
      _quantity,
      _difficulty,
      _environment,
      _distance,
      _unitPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.quantity > 0;

    return Card(
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name and Base Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (widget.service.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.service.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isSelected && widget.onAdd != null)
                  ElevatedButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else if (isSelected && widget.onRemove != null)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),

            if (isSelected) ...[
              const Divider(height: 24),
              // Multipliers selectors
              Text(
                'Dificuldade do Serviço',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Fácil',
                      label: Text('Fácil'),
                      icon: Icon(Icons.bolt, size: 16),
                    ),
                    ButtonSegment(
                      value: 'Médio',
                      label: Text('Médio'),
                      icon: Icon(Icons.electric_bolt, size: 16),
                    ),
                    ButtonSegment(
                      value: 'Difícil',
                      label: Text('Difícil'),
                      icon: Icon(Icons.flash_on, size: 16),
                    ),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _difficulty = newSelection.first);
                    _notifyChanges();
                  },
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    selectedBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    selectedForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ambiente
                  Expanded(
                    child: _buildDropdown<String>(
                      label: 'Ambiente',
                      value: _environment,
                      items: [
                        'Sala',
                        'Cozinha',
                        'Banheiro',
                        'Externo',
                        'Forro',
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _environment = val);
                          _notifyChanges();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Distância
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distância (m)',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller:
                              TextEditingController(
                                  text: _distance == 0
                                      ? ''
                                      : _distance.toInt().toString(),
                                )
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _distance == 0
                                        ? 0
                                        : _distance.toInt().toString().length,
                                  ),
                                ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixText: 'm',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final dist = double.tryParse(val) ?? 0;
                            // Update state without full rebuild of controller if possible
                            // But for simple fix we just use the controller approach
                            _distance = dist;
                            _notifyChanges();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quantidade e Unit Price summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantidade',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildCircleButton(
                            icon: Icons.remove,
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                                _notifyChanges();
                              }
                            },
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 40),
                            alignment: Alignment.center,
                            child: Text(
                              _quantity.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          _buildCircleButton(
                            icon: Icons.add,
                            onPressed: () {
                              setState(() => _quantity++);
                              _notifyChanges();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Preço p/ Unidade',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(_unitPrice),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Divider(height: 32),
              // Subtotal display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal do Item',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(_unitPrice * _quantity),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Valor Base: ${Formatters.formatCurrency(widget.service.unitPrice)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    item.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
