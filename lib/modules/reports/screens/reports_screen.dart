import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/subscription_viewmodel.dart';
import '../../../models/subscription_model.dart';
import '../models/report_models.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final subscription = user != null
        ? ref.watch(subscriptionProvider(user.uid)).value
        : null;

    // Check Premium access
    if (subscription?.tier != SubscriptionTier.premium) {
      return _buildUpgradePrompt(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog(context);
            },
            tooltip: 'Ajuda',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _buildReportTile(
            context,
            type: ReportType.monthlyRevenue,
            onTap: () => context.push('/reports/monthly-revenue'),
          ),
          const SizedBox(height: 12),
          _buildReportTile(
            context,
            type: ReportType.topServices,
            onTap: () => context.push('/reports/top-services'),
          ),
          const SizedBox(height: 12),
          _buildReportTile(
            context,
            type: ReportType.recurringClients,
            onTap: () => context.push('/reports/recurring-clients'),
          ),
          const SizedBox(height: 12),
          _buildReportTile(
            context,
            type: ReportType.monthComparison,
            onTap: () => context.push('/reports/month-comparison'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue.shade700, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Análise de Negócio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Relatórios detalhados com exportação em Excel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTile(
    BuildContext context, {
    required ReportType type,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(type.icon, style: const TextStyle(fontSize: 28)),
        ),
        title: Text(
          type.displayName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            type.description,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Relatórios Premium',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Acesse relatórios detalhados sobre seu negócio',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _buildFeatureItem('📊 Faturamento mensal detalhado'),
              _buildFeatureItem('🏆 Serviços mais vendidos'),
              _buildFeatureItem('👥 Análise de clientes recorrentes'),
              _buildFeatureItem('📈 Comparação entre períodos'),
              _buildFeatureItem('📄 Exportação para Excel'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.go('/subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Fazer Upgrade para Premium',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como usar os Relatórios'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Os relatórios fornecem insights valiosos sobre seu negócio:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('• Faturamento Mensal: veja o desempenho mês a mês'),
              SizedBox(height: 8),
              Text(
                '• Serviços Mais Vendidos: identifique seus produtos mais lucrativos',
              ),
              SizedBox(height: 8),
              Text(
                '• Clientes Recorrentes: saiba quem são seus melhores clientes',
              ),
              SizedBox(height: 8),
              Text('• Comparação Mensal: compare períodos diferentes'),
              SizedBox(height: 16),
              Text(
                'Todos os relatórios podem ser exportados para Excel!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
