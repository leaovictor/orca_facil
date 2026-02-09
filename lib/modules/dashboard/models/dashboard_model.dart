/// Dashboard metrics and data models
class DashboardMetrics {
  final double totalRevenue;
  final int budgetCount;
  final double averageTicket;
  final double monthlyGrowth; // Percentage
  final DateTime periodStart;
  final DateTime periodEnd;

  DashboardMetrics({
    required this.totalRevenue,
    required this.budgetCount,
    required this.averageTicket,
    required this.monthlyGrowth,
    required this.periodStart,
    required this.periodEnd,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      totalRevenue: 0,
      budgetCount: 0,
      averageTicket: 0,
      monthlyGrowth: 0,
      periodStart: DateTime.now(),
      periodEnd: DateTime.now(),
    );
  }
}

/// Monthly revenue data for charts
class MonthlyRevenue {
  final DateTime month;
  final double revenue;
  final int budgetCount;

  MonthlyRevenue({
    required this.month,
    required this.revenue,
    required this.budgetCount,
  });
}

/// Category distribution for pie chart
class CategoryDistribution {
  final String category;
  final double value;
  final int count;
  final double percentage;

  CategoryDistribution({
    required this.category,
    required this.value,
    required this.count,
    required this.percentage,
  });
}

/// Top client ranking
class TopClient {
  final String clientId;
  final String clientName;
  final double totalValue;
  final int budgetCount;
  final DateTime lastBudget;

  TopClient({
    required this.clientId,
    required this.clientName,
    required this.totalValue,
    required this.budgetCount,
    required this.lastBudget,
  });
}
