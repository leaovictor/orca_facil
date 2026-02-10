import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../widgets/budget_card.dart';
import '../../models/budget_model.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _previewBudget(BudgetModel budget) async {
    context.push('/budget/preview', extra: budget);
  }

  void _deleteBudget(String budgetId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Orçamento'),
        content: const Text(
          'Tem certeza que deseja excluir este orçamento? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(budgetViewModelProvider.notifier)
                    .deleteBudget(budgetId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Orçamento excluído com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendViaWhatsApp({
    required BudgetModel budget,
    required String userId,
  }) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      final success = await ref
          .read(budgetViewModelProvider.notifier)
          .sendBudgetViaWhatsApp(
            budget: budget,
            user: user,
            pdfUrl: null, // Could upload PDF to Firebase Storage and pass URL
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'WhatsApp aberto com sucesso!'
                  : 'Erro ao abrir WhatsApp. Verifique se está instalado.',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Orçamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/budget/new'),
            tooltip: 'Novo Orçamento',
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não logado'));
          }

          final budgetsAsync = ref.watch(budgetsProvider(user.uid));
          final subscriptionAsync = ref.watch(subscriptionProvider(user.uid));

          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente ou número...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),

              // Budgets List
              Expanded(
                child: budgetsAsync.when(
                  data: (budgets) {
                    final subscription = subscriptionAsync.value;
                    final canUseWhatsApp =
                        subscription?.canUseWhatsApp ?? false;

                    final filteredBudgets = _searchQuery.isEmpty
                        ? budgets
                        : budgets.where((b) {
                            final matchesClient = b.clientName
                                .toLowerCase()
                                .contains(_searchQuery);
                            final matchesNumber = b.budgetNumber
                                .toString()
                                .contains(_searchQuery);
                            return matchesClient || matchesNumber;
                          }).toList();

                    if (budgets.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  size: 80,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Nenhum orçamento criado',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Comece criando seu primeiro orçamento profissional agora mesmo.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                              ),
                              const SizedBox(height: 32),
                              FilledButton.icon(
                                onPressed: () => context.push('/budget/new'),
                                icon: const Icon(Icons.add),
                                label: const Text('Criar o Primeiro Orçamento'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (filteredBudgets.isEmpty) {
                      return const Center(
                        child: Text('Nenhum orçamento encontrado'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredBudgets.length,
                      itemBuilder: (context, index) {
                        final budget = filteredBudgets[index];
                        return BudgetCard(
                          budget: budget,
                          onTap: () {
                            _previewBudget(budget);
                          },
                          onShare: () => _previewBudget(budget),
                          onWhatsApp: canUseWhatsApp
                              ? () => _sendViaWhatsApp(
                                  budget: budget,
                                  userId: user.uid,
                                )
                              : null,
                          onDelete: () => _deleteBudget(budget.id),
                          canUseWhatsApp: canUseWhatsApp,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('Erro ao carregar orçamentos: $error'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }
}
