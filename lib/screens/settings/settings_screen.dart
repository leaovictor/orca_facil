import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_button.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authViewModelProvider.notifier).signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: userAsync.when(
        data: (user) {
          if (user == null)
            return const Center(child: Text('Usuário não encontrado'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perfil',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Nome'),
                        subtitle: Text(user.name),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('E-mail'),
                        subtitle: Text(user.email),
                      ),
                      if (user.phone != null)
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Telefone'),
                          subtitle: Text(user.phone!),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assinatura',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ref
                          .watch(subscriptionProvider(user.uid))
                          .when(
                            data: (subscription) {
                              if (subscription == null) {
                                return const Text('Carregando...');
                              }
                              return ListTile(
                                leading: Icon(
                                  subscription.tier.name == 'pro'
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: subscription.tier.name == 'pro'
                                      ? AppTheme.secondaryGreen
                                      : Colors.grey,
                                ),
                                title: Text(
                                  subscription.tier.name == 'pro'
                                      ? 'Plano Pro'
                                      : 'Plano Gratuito',
                                ),
                                subtitle: Text(
                                  subscription.tier.name == 'pro'
                                      ? 'Orçamentos ilimitados'
                                      : 'Até 5 orçamentos/mês (${subscription.budgetCount}/5)',
                                ),
                                trailing: subscription.tier.name == 'free'
                                    ? ElevatedButton(
                                        onPressed: () =>
                                            context.push('/subscription'),
                                        child: const Text('Upgrade'),
                                      )
                                    : null,
                              );
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('Erro ao carregar'),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aparência',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Modo escuro'),
                        subtitle: const Text(
                          'Alternar entre tema claro e escuro',
                        ),
                        value: user.isDarkMode,
                        onChanged: (value) {
                          // TODO: Implement theme toggle
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Sair',
                onPressed: _handleLogout,
                backgroundColor: AppTheme.errorColor,
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
