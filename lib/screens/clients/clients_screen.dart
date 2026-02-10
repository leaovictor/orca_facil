import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/client_model.dart';
import '../../viewmodels/client_viewmodel.dart';
import '../../widgets/client_card.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: clientsAsync.when(
        data: (clients) {
          final filteredClients = clients.where((client) {
            return client.name.toLowerCase().contains(_searchQuery) ||
                client.phone.contains(_searchQuery);
          }).toList();

          if (filteredClients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Nenhum cliente cadastrado'
                        : 'Nenhum cliente encontrado',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredClients.length,
            itemBuilder: (context, index) {
              final client = filteredClients[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClientCard(
                  client: client,
                  isSelected: false, // Not using selection in this screen
                  onTap: () =>
                      context.push('/clients/${client.id}', extra: client),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Erro ao carregar clientes: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Utilizar o formulário existente em client_step ou criar um novo modal
          _showAddClientDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddClientDialog(BuildContext context) {
    // Para agilizar, podemos redirecionar para a criação de orçamento ou criar um modal simples
    // Por enquanto, vamos planejar a criação de um formulário de cliente separado se necessário.
    // Mas o usuário pediu "gestão", então vamos implementar a edição/criação aqui também.
    context.push('/clients/new');
  }
}
