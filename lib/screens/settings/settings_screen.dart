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
                                radius: 24,
                                backgroundColor: Colors.grey[200],
                                child: ClipOval(
                                  child: Image.network(
                                    user.photoUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          );
                                        },
                                  ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assinatura',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                context.push('/settings/plan-details'),
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('Detalhes'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ref
                          .watch(subscriptionProvider(user.uid))
                          .when(
                            data: (subscription) {
                              if (subscription == null) {
                                return const Text('Carregando...');
                              }

                              IconData getIcon() {
                                switch (subscription.tier.name) {
                                  case 'premium':
                                    return Icons.diamond;
                                  case 'pro':
                                    return Icons.star;
                                  default:
                                    return Icons.star_border;
                                }
                              }

                              Color getColor() {
                                switch (subscription.tier.name) {
                                  case 'premium':
                                    return Colors.purple;
                                  case 'pro':
                                    return AppTheme.primaryBlue;
                                  default:
                                    return Colors.grey;
                                }
                              }

                              String getSubtitle() {
                                switch (subscription.tier.name) {
                                  case 'premium':
                                    return 'Recursos avançados + Dashboard';
                                  case 'pro':
                                    return 'Orçamentos ilimitados';
                                  default:
                                    return 'Até 5 orçamentos/mês (${subscription.budgetCount}/5)';
                                }
                              }

                              return Column(
                                children: [
                                  ListTile(
                                    leading: Icon(getIcon(), color: getColor()),
                                    title: Text(
                                      'Plano ${subscription.tierDisplayName}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: getColor(),
                                      ),
                                    ),
                                    subtitle: Text(getSubtitle()),
                                    trailing: subscription.tier.name == 'free'
                                        ? ElevatedButton(
                                            onPressed: () =>
                                                context.push('/subscription'),
                                            child: const Text('Upgrade'),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: subscription.isActive
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: subscription.isActive
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                            child: Text(
                                              subscription.isActive
                                                  ? 'Ativo'
                                                  : 'Inativo',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: subscription.isActive
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                  ),
                                  if (subscription.tier.name != 'free')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              context.push('/subscription'),
                                          icon: const Icon(Icons.settings),
                                          label: const Text(
                                            'Gerenciar Assinatura',
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
