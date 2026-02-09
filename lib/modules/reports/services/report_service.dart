import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_models.dart';
import '../../../models/budget_model.dart';

/// Service for generating business reports
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate monthly revenue report
  Future<MonthlyRevenueReport> generateMonthlyRevenueReport({
    required String userId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final budgets = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    double totalRevenue = 0;
    final revenueByService = <String, double>{};
    final dailyRevenueMap = <int, DailyRevenue>{};

    for (final doc in budgets.docs) {
      final budget = BudgetModel.fromSnapshot(doc);
      totalRevenue += budget.total;

      // Group by service
      for (final item in budget.items) {
        revenueByService[item.serviceName] =
            (revenueByService[item.serviceName] ?? 0) + item.total;
      }

      // Group by day
      final day = budget.createdAt.day;
      if (dailyRevenueMap.containsKey(day)) {
        final existing = dailyRevenueMap[day]!;
        dailyRevenueMap[day] = DailyRevenue(
          date: existing.date,
          revenue: existing.revenue + budget.total,
          budgetCount: existing.budgetCount + 1,
        );
      } else {
        dailyRevenueMap[day] = DailyRevenue(
          date: budget.createdAt,
          revenue: budget.total,
          budgetCount: 1,
        );
      }
    }

    final dailyBreakdown = dailyRevenueMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return MonthlyRevenueReport(
      userId: userId,
      month: month,
      totalRevenue: totalRevenue,
      budgetCount: budgets.docs.length,
      averageTicket: budgets.docs.isNotEmpty
          ? totalRevenue / budgets.docs.length
          : 0,
      revenueByService: revenueByService,
      dailyBreakdown: dailyBreakdown,
    );
  }

  /// Generate top services report
  Future<TopServicesReport> generateTopServicesReport({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final budgets = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
        .get();

    final serviceStats = <String, _ServiceStats>{};
    double totalRevenue = 0;

    for (final doc in budgets.docs) {
      final budget = BudgetModel.fromSnapshot(doc);
      for (final item in budget.items) {
        totalRevenue += item.total;

        if (serviceStats.containsKey(item.serviceName)) {
          final stats = serviceStats[item.serviceName]!;
          serviceStats[item.serviceName] = _ServiceStats(
            quantity: stats.quantity + item.quantity,
            totalRevenue: stats.totalRevenue + item.total,
          );
        } else {
          serviceStats[item.serviceName] = _ServiceStats(
            quantity: item.quantity,
            totalRevenue: item.total,
          );
        }
      }
    }

    // Convert to rankings and calculate percentages
    final rankings =
        serviceStats.entries
            .map(
              (entry) => ServiceRanking(
                serviceName: entry.key,
                quantity: entry.value.quantity,
                totalRevenue: entry.value.totalRevenue,
                percentage: totalRevenue > 0
                    ? (entry.value.totalRevenue / totalRevenue) * 100
                    : 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return TopServicesReport(
      userId: userId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      rankings: rankings,
    );
  }

  /// Generate recurring clients report
  Future<RecurringClientsReport> generateRecurringClientsReport({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final budgets = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
        .get();

    final clientStats = <String, _ClientStats>{};

    for (final doc in budgets.docs) {
      final budget = BudgetModel.fromSnapshot(doc);
      final clientKey = budget.clientName;

      if (clientStats.containsKey(clientKey)) {
        final stats = clientStats[clientKey]!;
        clientStats[clientKey] = _ClientStats(
          clientName: budget.clientName,
          clientPhone: budget.clientPhone,
          budgetCount: stats.budgetCount + 1,
          totalRevenue: stats.totalRevenue + budget.total,
          firstBudget: stats.firstBudget.isBefore(budget.createdAt)
              ? stats.firstBudget
              : budget.createdAt,
          lastBudget: stats.lastBudget.isAfter(budget.createdAt)
              ? stats.lastBudget
              : budget.createdAt,
        );
      } else {
        clientStats[clientKey] = _ClientStats(
          clientName: budget.clientName,
          clientPhone: budget.clientPhone,
          budgetCount: 1,
          totalRevenue: budget.total,
          firstBudget: budget.createdAt,
          lastBudget: budget.createdAt,
        );
      }
    }

    // Filter clients with more than 1 budget (recurring)
    final recurringClients =
        clientStats.values
            .where((stats) => stats.budgetCount > 1)
            .map(
              (stats) => ClientRecurrence(
                clientName: stats.clientName,
                clientPhone: stats.clientPhone,
                budgetCount: stats.budgetCount,
                totalRevenue: stats.totalRevenue,
                firstBudget: stats.firstBudget,
                lastBudget: stats.lastBudget,
              ),
            )
            .toList()
          ..sort((a, b) => b.budgetCount.compareTo(a.budgetCount));

    return RecurringClientsReport(
      userId: userId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      clients: recurringClients,
    );
  }

  /// Generate month comparison report
  Future<MonthComparisonReport> generateMonthComparisonReport({
    required String userId,
    required DateTime month1,
    required DateTime month2,
  }) async {
    final report1 = await generateMonthlyRevenueReport(
      userId: userId,
      month: month1,
    );

    final report2 = await generateMonthlyRevenueReport(
      userId: userId,
      month: month2,
    );

    final month1Stats = MonthStats(
      totalRevenue: report1.totalRevenue,
      budgetCount: report1.budgetCount,
      averageTicket: report1.averageTicket,
    );

    final month2Stats = MonthStats(
      totalRevenue: report2.totalRevenue,
      budgetCount: report2.budgetCount,
      averageTicket: report2.averageTicket,
    );

    final revenueChange = report1.totalRevenue > 0
        ? ((report2.totalRevenue - report1.totalRevenue) /
                  report1.totalRevenue) *
              100
        : 0;

    final averageTicketChange = report1.averageTicket > 0
        ? ((report2.averageTicket - report1.averageTicket) /
                  report1.averageTicket) *
              100
        : 0;

    final comparison = ComparisonMetrics(
      revenueChange: revenueChange.toDouble(),
      budgetCountChange: report2.budgetCount - report1.budgetCount,
      averageTicketChange: averageTicketChange.toDouble(),
    );

    return MonthComparisonReport(
      userId: userId,
      month1: month1,
      month2: month2,
      month1Stats: month1Stats,
      month2Stats: month2Stats,
      comparison: comparison,
    );
  }
}

// Helper classes for internal calculations
class _ServiceStats {
  final int quantity;
  final double totalRevenue;

  _ServiceStats({required this.quantity, required this.totalRevenue});
}

class _ClientStats {
  final String clientName;
  final String clientPhone;
  final int budgetCount;
  final double totalRevenue;
  final DateTime firstBudget;
  final DateTime lastBudget;

  _ClientStats({
    required this.clientName,
    required this.clientPhone,
    required this.budgetCount,
    required this.totalRevenue,
    required this.firstBudget,
    required this.lastBudget,
  });
}
