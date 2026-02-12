import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/subscription_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../widgets/custom_button.dart';

class PlanDetailsScreen extends ConsumerStatefulWidget {
  const PlanDetailsScreen({super.key});

  @override
  ConsumerState<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends ConsumerState<PlanDetailsScreen> {
  bool _isSyncing = false;

  Future<void> _syncFromStripe() async {
    setState(() => _isSyncing = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('syncSubscriptionFromStripe');
      final result = await callable.call();

      if (mounted) {
        final success = result.data['success'] as bool;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] as String),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sincronizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final subscriptionAsync = user != null
        ? ref.watch(subscriptionProvider(user.uid))
        : const AsyncValue<SubscriptionModel?>.loading();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Plano'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryBlue.withOpacity(0.05), Colors.white],
          ),
        ),
        child: subscriptionAsync.when(
          data: (subscription) => _buildContent(context, subscription),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SubscriptionModel? subscription) {
    final user = ref.watch(currentUserProvider).value;
    final sub = subscription ?? SubscriptionModel.createFree(user?.uid ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Plan Card
          _buildCurrentPlanCard(sub),
          const SizedBox(height: 24),

          // Plan Details Card
          _buildPlanDetailsCard(sub),
          const SizedBox(height: 24),

          // Features Access Card
          _buildFeaturesCard(sub),
          const SizedBox(height: 24),

          // Actions
          _buildActions(context, sub),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(SubscriptionModel sub) {
    Color getTierColor() {
      switch (sub.tier) {
        case SubscriptionTier.premium:
          return Colors.purple;
        case SubscriptionTier.pro:
          return AppTheme.primaryBlue;
        case SubscriptionTier.free:
          return Colors.grey;
      }
    }

    IconData getTierIcon() {
      switch (sub.tier) {
        case SubscriptionTier.premium:
          return Icons.diamond;
        case SubscriptionTier.pro:
          return Icons.star;
        case SubscriptionTier.free:
          return Icons.account_circle;
      }
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [getTierColor(), getTierColor().withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(getTierIcon(), size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Plano ${sub.tierDisplayName}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sub.isActive
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sub.isActive ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sub.isActive ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sub.isActive ? 'Ativo' : 'Inativo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetailsCard(SubscriptionModel sub) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações da Assinatura',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Plano', sub.tierDisplayName, Icons.loyalty),
            const Divider(height: 24),
            _buildDetailRow(
              'Status',
              sub.isActive ? 'Ativo' : 'Inativo',
              Icons.info_outline,
              valueColor: sub.isActive ? Colors.green : Colors.red,
            ),
            if (sub.expiryDate != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'Expira em',
                dateFormat.format(sub.expiryDate!),
                Icons.calendar_today,
                valueColor: sub.isExpired ? Colors.red : null,
              ),
            ],
            const Divider(height: 24),
            _buildDetailRow(
              'Período iniciado em',
              dateFormat.format(sub.periodStart),
              Icons.calendar_month,
            ),
            if (sub.tier == SubscriptionTier.free) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'Orçamentos criados',
                '${sub.budgetCount} / 5',
                Icons.description,
                valueColor: sub.hasReachedFreeLimit ? Colors.red : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesCard(SubscriptionModel sub) {
    final features = [
      _Feature(
        'Orçamentos Ilimitados',
        sub.canCreateBudget && sub.tier != SubscriptionTier.free,
        Icons.description,
      ),
      _Feature('Sem Marca d\'água', !sub.hasWatermark, Icons.clear),
      _Feature('Dashboard Financeiro', sub.canAccessDashboard, Icons.dashboard),
      _Feature('Relatórios Avançados', sub.canAccessReports, Icons.assessment),
      _Feature('Exportar Excel', sub.canExportExcel, Icons.file_download),
      _Feature('Integração WhatsApp', sub.canUseWhatsApp, Icons.chat),
      _Feature('Salvar Clientes', sub.canSaveClients, Icons.people),
      _Feature('Orçamentos Recorrentes', sub.canCreateRecurrence, Icons.repeat),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recursos Disponíveis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      feature.available ? Icons.check_circle : Icons.cancel,
                      color: feature.available ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: feature.available
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                    if (!feature.available && sub.tier == SubscriptionTier.free)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PRO/PREMIUM',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, SubscriptionModel sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sync button for debugging
        if (sub.tier != SubscriptionTier.free)
          CustomButton(
            text: _isSyncing ? 'Sincronizando...' : 'Atualizar do Stripe',
            onPressed: _isSyncing ? () {} : _syncFromStripe,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync, color: Colors.white),
          ),

        if (sub.tier != SubscriptionTier.free) const SizedBox(height: 12),

        // Manage subscription or Upgrade
        if (sub.tier == SubscriptionTier.free)
          CustomButton(
            text: 'Ver Planos Disponíveis',
            onPressed: () => context.push('/subscription'),
            backgroundColor: AppTheme.primaryBlue,
            textColor: Colors.white,
            icon: const Icon(Icons.upgrade, color: Colors.white),
          )
        else
          CustomButton(
            text: 'Gerenciar Assinatura',
            onPressed: () => context.push('/subscription'),
            backgroundColor: AppTheme.primaryBlue,
            textColor: Colors.white,
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
      ],
    );
  }
}

class _Feature {
  final String name;
  final bool available;
  final IconData icon;

  _Feature(this.name, this.available, this.icon);
}
