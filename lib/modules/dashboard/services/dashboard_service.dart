import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_model.dart';

/// Service for calculating dashboard metrics and aggregations
class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get dashboard metrics for a user in a given period
  Future<DashboardMetrics> getMetrics({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final budgets = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(periodEnd),
          )
          .get();

      if (budgets.docs.isEmpty) {
        return DashboardMetrics.empty();
      }

      double totalRevenue = 0;
      for (var doc in budgets.docs) {
        totalRevenue += (doc.data()['total'] as num).toDouble();
      }

      final budgetCount = budgets.docs.length;
      final averageTicket = budgetCount > 0 ? totalRevenue / budgetCount : 0.0;

      // Calculate growth
      final monthlyGrowth = await _calculateMonthlyGrowth(userId, periodStart);

      return DashboardMetrics(
        totalRevenue: totalRevenue.toDouble(),
        budgetCount: budgetCount,
        averageTicket: averageTicket.toDouble(),
        monthlyGrowth: monthlyGrowth,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate monthly growth percentage
  Future<double> _calculateMonthlyGrowth(
    String userId,
    DateTime currentPeriodStart,
  ) async {
    try {
      // Current month
      final currentMonthEnd = DateTime(
        currentPeriodStart.year,
        currentPeriodStart.month + 1,
        0,
      );

      final currentMetrics = await getMetrics(
        userId: userId,
        periodStart: currentPeriodStart,
        periodEnd: currentMonthEnd,
      );

      // Previous month
      final previousMonthStart = DateTime(
        currentPeriodStart.year,
        currentPeriodStart.month - 1,
        1,
      );
      final previousMonthEnd = DateTime(
        currentPeriodStart.year,
        currentPeriodStart.month,
        0,
      );

      final previousMetrics = await getMetrics(
        userId: userId,
        periodStart: previousMonthStart,
        periodEnd: previousMonthEnd,
      );

      if (previousMetrics.totalRevenue == 0) return 0;

      final growth =
          ((currentMetrics.totalRevenue - previousMetrics.totalRevenue) /
              previousMetrics.totalRevenue) *
          100;

      return growth;
    } catch (e) {
      return 0;
    }
  }

  /// Get monthly revenue for the last N months
  Future<List<MonthlyRevenue>> getMonthlyRevenue({
    required String userId,
    int months = 6,
  }) async {
    final List<MonthlyRevenue> revenues = [];
    final now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);

      final budgets = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get();

      double monthRevenue = 0;
      for (var doc in budgets.docs) {
        monthRevenue += (doc.data()['total'] as num).toDouble();
      }

      revenues.add(
        MonthlyRevenue(
          month: monthStart,
          revenue: monthRevenue,
          budgetCount: budgets.docs.length,
        ),
      );
    }

    return revenues;
  }

  /// Get category distribution for pie chart
  Future<List<CategoryDistribution>> getCategoryDistribution({
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

    // Group by service category
    final Map<String, CategoryData> categoryMap = {};
    double totalValue = 0;

    for (var doc in budgets.docs) {
      final items = doc.data()['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final serviceName = item['serviceName'] as String? ?? 'Outros';
        final itemTotal =
            (item['unitPrice'] as num).toDouble() * (item['quantity'] as int);

        if (categoryMap.containsKey(serviceName)) {
          categoryMap[serviceName]!.value += itemTotal;
          categoryMap[serviceName]!.count += 1;
        } else {
          categoryMap[serviceName] = CategoryData(value: itemTotal, count: 1);
        }
        totalValue += itemTotal;
      }
    }

    // Convert to list with percentages
    return categoryMap.entries.map((entry) {
      return CategoryDistribution(
        category: entry.key,
        value: entry.value.value,
        count: entry.value.count,
        percentage: totalValue > 0 ? (entry.value.value / totalValue) * 100 : 0,
      );
    }).toList()..sort(
      (a, b) => b.value.compareTo(a.value),
    ); // Sort by value descending
  }

  /// Get top clients ranking
  Future<List<TopClient>> getTopClients({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
    int limit = 5,
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

    // Group by client
    final Map<String, ClientData> clientMap = {};

    for (var doc in budgets.docs) {
      final clientId = doc.data()['clientId'] as String;
      final clientName = doc.data()['clientName'] as String;
      final total = (doc.data()['total'] as num).toDouble();
      final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();

      if (clientMap.containsKey(clientId)) {
        clientMap[clientId]!.totalValue += total;
        clientMap[clientId]!.budgetCount += 1;
        if (createdAt.isAfter(clientMap[clientId]!.lastBudget)) {
          clientMap[clientId]!.lastBudget = createdAt;
        }
      } else {
        clientMap[clientId] = ClientData(
          clientName: clientName,
          totalValue: total,
          budgetCount: 1,
          lastBudget: createdAt,
        );
      }
    }

    // Convert to list and sort
    final topClients =
        clientMap.entries
            .map(
              (entry) => TopClient(
                clientId: entry.key,
                clientName: entry.value.clientName,
                totalValue: entry.value.totalValue,
                budgetCount: entry.value.budgetCount,
                lastBudget: entry.value.lastBudget,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalValue.compareTo(a.totalValue));

    return topClients.take(limit).toList();
  }

  /// Stream dashboard metrics (real-time updates)
  Stream<DashboardMetrics> streamMetrics({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
        .snapshots()
        .asyncMap(
          (_) => getMetrics(
            userId: userId,
            periodStart: periodStart,
            periodEnd: periodEnd,
          ),
        );
  }
}

// Helper classes for internal data aggregation
class CategoryData {
  double value;
  int count;

  CategoryData({required this.value, required this.count});
}

class ClientData {
  String clientName;
  double totalValue;
  int budgetCount;
  DateTime lastBudget;

  ClientData({
    required this.clientName,
    required this.totalValue,
    required this.budgetCount,
    required this.lastBudget,
  });
}
