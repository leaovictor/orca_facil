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
    double unitPrice,
  ) {
    final selectedServices = ref.read(selectedServicesProvider);

    // Check if service already added
    final existing = selectedServices
        .where((item) => item.serviceId == serviceId)
        .firstOrNull;

    if (existing != null) {
      // Increase quantity
      final updated = selectedServices.map((item) {
        if (item.serviceId == serviceId) {
          return BudgetItem(
            serviceId: item.serviceId,
            serviceName: item.serviceName,
            serviceDescription: item.serviceDescription,
            unitPrice: item.unitPrice,
            quantity: item.quantity + 1,
          );
        }
        return item;
      }).toList();

      ref.read(selectedServicesProvider.notifier).state = updated;
    } else {
      // Add new service
      final newItem = BudgetItem(
        serviceId: serviceId,
        serviceName: serviceName,
        serviceDescription: serviceDescription,
        unitPrice: unitPrice,
        quantity: 1,
      );

      ref.read(selectedServicesProvider.notifier).state = [
        ...selectedServices,
        newItem,
      ];
    }
  }

  void _removeService(String serviceId) {
    final selectedServices = ref.read(selectedServicesProvider);
    ref.read(selectedServicesProvider.notifier).state = selectedServices
        .where((item) => item.serviceId != serviceId)
        .toList();
  }

  void _updateQuantity(String serviceId, int newQuantity) {
    if (newQuantity <= 0) {
      _removeService(serviceId);
      return;
    }

    final selectedServices = ref.read(selectedServicesProvider);
    final updated = selectedServices.map((item) {
      if (item.serviceId == serviceId) {
        return BudgetItem(
          serviceId: item.serviceId,
          serviceName: item.serviceName,
          serviceDescription: item.serviceDescription,
          unitPrice: item.unitPrice,
          quantity: newQuantity,
        );
      }
      return item;
    }).toList();

    ref.read(selectedServicesProvider.notifier).state = updated;
  }

  int _getQuantity(String serviceId) {
    final selectedServices = ref.watch(selectedServicesProvider);
    final item = selectedServices
        .where((item) => item.serviceId == serviceId)
        .firstOrNull;
    return item?.quantity ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);
    final selectedServices = ref.watch(selectedServicesProvider);
    final total = ref.watch(budgetTotalProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Adicione os serviços que serão realizados',
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
                const SizedBox(height: 16),

                // Selected services section
                if (selectedServices.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Serviços Selecionados (${selectedServices.length})',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...selectedServices.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.serviceName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      Text(
                                        '${item.quantity}x ${Formatters.formatCurrency(item.unitPrice)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(item.total),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                ],

                // Available services
                Text(
                  'Serviços Disponíveis',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                servicesAsync.when(
                  data: (services) {
                    final filteredServices = _searchQuery.isEmpty
                        ? services
                        : services
                              .where(
                                (s) =>
                                    s.name.toLowerCase().contains(
                                      _searchQuery,
                                    ) ||
                                    s.description.toLowerCase().contains(
                                      _searchQuery,
                                    ),
                              )
                              .toList();

                    if (filteredServices.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.build_circle,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Nenhum serviço cadastrado'
                                    : 'Nenhum serviço encontrado',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cadastre serviços na tela de Serviços',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredServices.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final service = filteredServices[index];
                        final quantity = _getQuantity(service.id);

                        return ServiceCard(
                          service: service,
                          quantity: quantity,
                          showQuantityControls: true,
                          onAdd: () => _addService(
                            service.id,
                            service.name,
                            service.description,
                            service.unitPrice,
                          ),
                          onRemove: () => _removeService(service.id),
                          onQuantityChanged: (newQuantity) =>
                              _updateQuantity(service.id, newQuantity),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Erro ao carregar serviços: $error',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                      'Total',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
                  '${selectedServices.length} ${selectedServices.length == 1 ? 'serviço' : 'serviços'}',
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
