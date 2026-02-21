import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';

class FreeSettingsScreen extends ConsumerWidget {
  const FreeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          if (user != null) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null ? Text(user.name[0]) : null,
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/settings/profile'),
              ),
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Assinar Premium'),
            subtitle: const Text('Desbloqueie todos os recursos'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/subscription'),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Tema'),
            trailing: DropdownButton<ThemeMode>(
              value: ref.watch(themeProvider),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Auto')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
              ],
              onChanged: (mode) {
                if (mode != null)
                  ref.read(themeProvider.notifier).setTheme(mode);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
