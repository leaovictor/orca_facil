import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../../models/subscription_model.dart';
import '../../../viewmodels/subscription_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final subscription = user != null
        ? ref.watch(subscriptionProvider(user.uid)).value
        : null;

    // Check if user has Premium access
    if (subscription?.tier != SubscriptionTier.premium) {
      return _buildUpgradePrompt(context);
    }

    final metricsAsync = ref.watch(currentMonthMetricsProvider);
    final monthlyRevenueAsync = ref.watch(monthlyRevenueProvider);
    final categoryDistAsync = ref.watch(categoryDistributionProvider);
    final topClientsAsync = ref.watch(topClientsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentMonthMetricsProvider);
          ref.invalidate(monthlyRevenueProvider);
          ref.invalidate(categoryDistributionProvider);
          ref.invalidate(topClientsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Dashboard Financeiro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now()),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Metrics Cards
              metricsAsync.when(
                data: (metrics) => _buildMetricsCards(context, metrics),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Monthly Revenue Chart
              Text(
                'Faturamento (últimos 6 meses)',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              monthlyRevenueAsync.when(
                data: (revenues) => _buildRevenueChart(context, revenues),
                loading: () => const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Category Distribution
              Text(
                'Distribuição por Serviço',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              categoryDistAsync.when(
                data: (categories) => _buildCategoryChart(context, categories),
                loading: () => const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Top Clients
              Text(
                'Top 5 Clientes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              topClientsAsync.when(
                data: (clients) => _buildTopClientsList(context, clients),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Dashboard Premium',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade para Premium e tenha acesso a:',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildFeatureItem('📊 Métricas financeiras em tempo real'),
            _buildFeatureItem('📈 Gráficos de faturamento'),
            _buildFeatureItem('🎯 Análise de serviços'),
            _buildFeatureItem('👥 Ranking de clientes'),
            _buildFeatureItem('📄 Relatórios exportáveis'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.push('/subscription');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Fazer Upgrade'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [Text(text, style: const TextStyle(fontSize: 16))]),
    );
  }

  Widget _buildMetricsCards(BuildContext context, metrics) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          context,
          icon: Icons.attach_money,
          title: 'Faturamento',
          value: currencyFormat.format(metrics.totalRevenue),
          color: Colors.green,
        ),
        _buildMetricCard(
          context,
          icon: Icons.description_outlined,
          title: 'Orçamentos',
          value: metrics.budgetCount.toString(),
          color: Colors.blue,
        ),
        _buildMetricCard(
          context,
          icon: Icons.calculate_outlined,
          title: 'Ticket Médio',
          value: currencyFormat.format(metrics.averageTicket),
          color: Colors.orange,
        ),
        _buildMetricCard(
          context,
          icon: metrics.monthlyGrowth >= 0
              ? Icons.trending_up
              : Icons.trending_down,
          title: 'Crescimento',
          value: '${metrics.monthlyGrowth.toStringAsFixed(1)}%',
          color: metrics.monthlyGrowth >= 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, List revenues) {
    if (revenues.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final spots = revenues.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.revenue);
    }).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        'R\$${(value / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= revenues.length)
                        return const Text('');
                      final month = revenues[value.toInt()].month;
                      return Text(
                        DateFormat('MMM', 'pt_BR').format(month),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, List categories) {
    if (categories.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categories.take(6).toList().asMap().entries.map((
                    entry,
                  ) {
                    final idx = entry.key;
                    final cat = entry.value;
                    return PieChartSectionData(
                      value: cat.value,
                      title: '${cat.percentage.toStringAsFixed(0)}%',
                      color: colors[idx % colors.length],
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: categories.take(6).toList().asMap().entries.map((
                entry,
              ) {
                final idx = entry.key;
                final cat = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[idx % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(cat.category, style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClientsList(BuildContext context, List clients) {
    if (clients.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Sem clientes para exibir',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: clients.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final client = clients[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              client.clientName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${client.budgetCount} orçamentos'),
            trailing: Text(
              currencyFormat.format(client.totalValue),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }
}
