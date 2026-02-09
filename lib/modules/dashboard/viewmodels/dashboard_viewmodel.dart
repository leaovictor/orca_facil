import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';

/// Provider for DashboardService
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

/// Provider for current month metrics
final currentMonthMetricsProvider =
    StreamProvider.autoDispose<DashboardMetrics>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) {
        return Stream.value(DashboardMetrics.empty());
      }

      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      final service = ref.watch(dashboardServiceProvider);
      return service.streamMetrics(
        userId: user.uid,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
    });

/// Provider for monthly revenue data (last 6 months)
final monthlyRevenueProvider = FutureProvider.autoDispose<List<MonthlyRevenue>>(
  (ref) async {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return [];

    final service = ref.watch(dashboardServiceProvider);
    return service.getMonthlyRevenue(userId: user.uid, months: 6);
  },
);

/// Provider for category distribution
final categoryDistributionProvider =
    FutureProvider.autoDispose<List<CategoryDistribution>>((ref) async {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return [];

      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      final service = ref.watch(dashboardServiceProvider);
      return service.getCategoryDistribution(
        userId: user.uid,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
    });

/// Provider for top clients
final topClientsProvider = FutureProvider.autoDispose<List<TopClient>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  final now = DateTime.now();
  final periodStart = DateTime(now.year, now.month, 1);
  final periodEnd = DateTime(now.year, now.month + 1, 0);

  final service = ref.watch(dashboardServiceProvider);
  return service.getTopClients(
    // Corrected to getTopClients
    userId: user.uid,
    periodStart: periodStart,
    periodEnd: periodEnd,
    limit: 5,
  );
});
