import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/budget_wizard_providers.dart';
import '../../../viewmodels/service_viewmodel.dart';
import '../../../widgets/service_card.dart';
import '../../../models/budget_model.dart';
import '../../../core/utils/formatters.dart';

class ServiceStep extends ConsumerStatefulWidget {
  const ServiceStep({super.key});

  @override
  ConsumerState<ServiceStep> createState() => _ServiceStepState();
}

class _ServiceStepState extends ConsumerState<ServiceStep> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addService(
    String serviceId,
    String serviceName,
    String serviceDescription,
    double basePrice,
  ) {
    final selectedServices = ref.read(selectedServicesProvider);

    // Add new service with default settings
    final newItem = BudgetItem(
      serviceId: serviceId,
      serviceName: serviceName,
      serviceDescription: serviceDescription,
      basePrice: basePrice,
      unitPrice: basePrice, // Initial unit price = base
      quantity: 1,
      difficulty: 'Fácil',
      environment: 'Sala',
      distance: 0,
    );

    ref.read(selectedServicesProvider.notifier).state = [
      ...selectedServices,
      newItem,
    ];
  }

  void _updateServiceItem(
    String serviceId,
    int quantity,
    String difficulty,
    String environment,
    double distance,
    double unitPrice,
  ) {
    final selectedServices = ref.read(selectedServicesProvider);
    final updated = selectedServices.map((item) {
      if (item.serviceId == serviceId) {
        return BudgetItem(
          serviceId: item.serviceId,
          serviceName: item.serviceName,
          serviceDescription: item.serviceDescription,
          basePrice: item.basePrice,
          unitPrice: unitPrice,
          quantity: quantity,
          difficulty: difficulty,
          environment: environment,
          distance: distance,
        );
      }
      return item;
    }).toList();

    ref.read(selectedServicesProvider.notifier).state = updated;
  }

  void _removeService(String serviceId) {
    final selectedServices = ref.read(selectedServicesProvider);
    ref.read(selectedServicesProvider.notifier).state = selectedServices
        .where((item) => item.serviceId != serviceId)
        .toList();
  }

  BudgetItem? _getSelectedItem(String serviceId) {
    final selectedServices = ref.watch(selectedServicesProvider);
    return selectedServices
        .where((item) => item.serviceId == serviceId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);
    final selectedServices = ref.watch(selectedServicesProvider);
    final total = ref.watch(budgetTotalProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Text(
                'Selecione os serviços',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personalize cada serviço com nível de dificuldade e ambiente.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar serviço...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
              const SizedBox(height: 24),

              // Available services list
              servicesAsync.when(
                data: (services) {
                  final filteredServices = _searchQuery.isEmpty
                      ? services
                      : services
                            .where(
                              (s) =>
                                  s.name.toLowerCase().contains(_searchQuery) ||
                                  s.description.toLowerCase().contains(
                                    _searchQuery,
                                  ),
                            )
                            .toList();

                  if (filteredServices.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('Nenhum serviço encontrado'),
                      ),
                    );
                  }

                  return Column(
                    children: filteredServices.map((service) {
                      final selectedItem = _getSelectedItem(service.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ServiceCard(
                          service: service,
                          quantity: selectedItem?.quantity ?? 0,
                          difficulty: selectedItem?.difficulty ?? 'Fácil',
                          environment: selectedItem?.environment ?? 'Sala',
                          distance: selectedItem?.distance ?? 0,
                          onAdd: () => _addService(
                            service.id,
                            service.name,
                            service.description,
                            service.unitPrice,
                          ),
                          onRemove: () => _removeService(service.id),
                          onChanged: (qty, diff, env, dist, price) =>
                              _updateServiceItem(
                                service.id,
                                qty,
                                diff,
                                env,
                                dist,
                                price,
                              ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erro: $e'),
              ),
            ],
          ),
        ),

        // Total bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL ESTIMADO',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                    ),
                    Text(
                      Formatters.formatCurrency(total),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Text(
                  '${selectedServices.length} itens',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
