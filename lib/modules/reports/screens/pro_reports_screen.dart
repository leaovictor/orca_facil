import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProReportsScreen extends StatelessWidget {
  const ProReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'RELATÓRIOS ESSENCIAIS',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.0,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportTile(
            context,
            title: 'Faturamento Mensal',
            subtitle: 'Acompanhe suas receitas mês a mês',
            icon: Icons.attach_money,
            onTap: () => context.push('/reports/monthly-revenue'),
          ),
          const SizedBox(height: 12),
          _buildReportTile(
            context,
            title: 'Serviços Mais Vendidos',
            subtitle: 'Saiba quais serviços trazem mais retorno',
            icon: Icons.star_border,
            onTap: () => context.push('/reports/top-services'),
          ),
          const SizedBox(height: 12),
          _buildReportTile(
            context,
            title: 'Clientes Recorrentes',
            subtitle: 'Identifique seus clientes fiéis',
            icon: Icons.people_outline,
            onTap: () => context.push('/reports/recurring-clients'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
