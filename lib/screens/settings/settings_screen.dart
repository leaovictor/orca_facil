import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_button.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/theme_viewmodel.dart';

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
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Perfil',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.push('/settings/profile'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: user.photoUrl != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  user.photoUrl!,
                                  webHtmlElementStrategy:
                                      WebHtmlElementStrategy.prefer,
                                ),
                              )
                            : const Icon(Icons.person),
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
                                      ? AppTheme.secondaryOrange
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
                        'Informações de Pagamento',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chave Pix para seus orçamentos',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: user.pixKey,
                        decoration: const InputDecoration(
                          labelText: 'Chave Pix',
                          hintText: 'CPF, Email, Telefone ou Aleatória',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pix),
                        ),
                        onFieldSubmitted: (value) async {
                          if (value.trim() == user.pixKey) return;

                          try {
                            await ref
                                .read(authViewModelProvider.notifier)
                                .updateProfile(pixKey: value.trim());

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Chave Pix atualizada!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao atualizar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
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
                      Consumer(
                        builder: (context, ref, child) {
                          final themeMode = ref.watch(themeProvider);
                          return SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<ThemeMode>(
                              segments: const [
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.system,
                                  label: Text('Auto'),
                                  icon: Icon(Icons.brightness_auto),
                                ),
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.light,
                                  label: Text('Claro'),
                                  icon: Icon(Icons.light_mode),
                                ),
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.dark,
                                  label: Text('Escuro'),
                                  icon: Icon(Icons.dark_mode),
                                ),
                              ],
                              selected: {themeMode},
                              onSelectionChanged:
                                  (Set<ThemeMode> newSelection) {
                                    ref
                                        .read(themeProvider.notifier)
                                        .setTheme(newSelection.first);
                                  },
                            ),
                          );
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
