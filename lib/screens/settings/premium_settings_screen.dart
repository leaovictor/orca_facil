import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';

class PremiumSettingsScreen extends ConsumerWidget {
  const PremiumSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate
      appBar: AppBar(
        title: Text(
          'ACCOUNT & PREFERENCES',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade900.withOpacity(0.5),
                  Colors.blue.shade900.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    backgroundColor: Colors.black,
                    child: user?.photoUrl == null && user != null
                        ? Text(
                            user.name[0],
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Premium User',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Premium Member',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.amber,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () => context.push('/settings/profile'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _buildSettingsGroup(
            context,
            title: 'WORKSPACE',
            children: [
              _buildSwitchTile(
                'Dark Mode',
                true,
                (val) {},
              ), // Always on distinct visuals
              _buildActionTile(
                Icons.credit_card,
                'Subscription Management',
                () => context.push('/subscription'),
              ),
              _buildActionTile(
                Icons.business,
                'Business Profile',
                () => context.push('/settings/profile'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSettingsGroup(
            context,
            title: 'INTEGRATIONS',
            children: [
              _buildSwitchTile('WhatsApp CRM', true, (val) {}),
              _buildSwitchTile('Calendar Sync', false, (val) {}),
            ],
          ),

          const SizedBox(height: 32),

          TextButton.icon(
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: Text(
              'SIGN OUT',
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: GoogleFonts.outfit(color: Colors.white)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(title, style: GoogleFonts.outfit(color: Colors.white)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.purpleAccent,
        activeTrackColor: Colors.purple.withOpacity(0.3),
      ),
    );
  }
}
