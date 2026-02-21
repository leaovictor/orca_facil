import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';

class ProSettingsScreen extends ConsumerWidget {
  const ProSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Professional off-white
      appBar: AppBar(
        title: Text(
          'CONFIGURAÇÕES',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.0,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionHeader('PERFIL PROFISSIONAL'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null && user != null
                    ? Text(
                        user.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                user?.name ?? 'Usuário',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                user?.email ?? '',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              trailing: TextButton(
                onPressed: () => context.push('/settings/profile'),
                child: const Text('EDITAR'),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // System Settings
          _buildSectionHeader('SISTEMA'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.star,
                  title: 'Plano Pro Ativo',
                  subtitle: 'Gerenciar Assinatura',
                  onTap: () => context.push('/subscription'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  icon: Icons.palette,
                  title: 'Aparência',
                  subtitle: 'Modo Escuro / Claro',
                  trailing: DropdownButton<ThemeMode>(
                    value: ref.watch(themeProvider),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Auto'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Claro'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Escuro'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null)
                        ref.read(themeProvider.notifier).setTheme(mode);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          OutlinedButton.icon(
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('SAIR DA CONTA'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700], size: 20),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}
