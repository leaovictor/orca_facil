import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/budget_wizard_providers.dart';
import '../../../viewmodels/client_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../widgets/client_card.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';

class ClientStep extends ConsumerStatefulWidget {
  const ClientStep({super.key});

  @override
  ConsumerState<ClientStep> createState() => _ClientStepState();
}

class _ClientStepState extends ConsumerState<ClientStep> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showNewClientForm = false;
  bool _isCreating = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      // Get the current user ID
      final authState = ref.read(authStateProvider);
      final userId = authState.value?.uid;

      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      await ref
          .read(clientViewModelProvider.notifier)
          .createClient(
            userId: userId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            notes: _notesController.text.trim(),
          );

      // The newly created client will appear in the stream automatically
      // We'll select it after a short delay
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _showNewClientForm = false;
        _isCreating = false;
      });

      // Clear form
      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
      _notesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente criado com sucesso!')),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar cliente: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);
    final selectedClient = ref.watch(selectedClientProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Selecione ou crie um cliente',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Para quem você está criando este orçamento?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Search bar
          if (!_showNewClientForm)
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
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

          // New client button
          if (!_showNewClientForm)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _showNewClientForm = true);
                },
                icon: const Icon(Icons.add),
                label: const Text('Novo Cliente'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // New client form
          if (_showNewClientForm)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Novo Cliente',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _showNewClientForm = false);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Nome',
                        hint: 'Nome do cliente',
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome é obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Telefone',
                        hint: '(00) 00000-0000',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [Formatters.phoneFormatter],
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Endereço',
                        hint: 'Endereço completo',
                        prefixIcon: Icons.location_on,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _notesController,
                        label: 'Observações',
                        hint: 'Informações adicionais',
                        prefixIcon: Icons.note,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Criar Cliente',
                        onPressed: _createClient,
                        isLoading: _isCreating,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Client list
          if (!_showNewClientForm)
            clientsAsync.when(
              data: (clients) {
                final filteredClients = _searchQuery.isEmpty
                    ? clients
                    : clients
                          .where(
                            (c) =>
                                c.name.toLowerCase().contains(_searchQuery) ||
                                c.phone.contains(_searchQuery),
                          )
                          .toList();

                if (filteredClients.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Nenhum cliente cadastrado'
                                : 'Nenhum cliente encontrado',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crie seu primeiro cliente acima',
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
                  itemCount: filteredClients.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    final isSelected = selectedClient?.id == client.id;

                    return ClientCard(
                      client: client,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(selectedClientProvider.notifier).state =
                            client;
                      },
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
                    'Erro ao carregar clientes: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
