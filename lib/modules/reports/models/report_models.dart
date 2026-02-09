import 'package:intl/intl.dart';

/// Report types available in the system
enum ReportType {
  monthlyRevenue,
  topServices,
  recurringClients,
  monthComparison,
}

extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.monthlyRevenue:
        return 'Faturamento Mensal';
      case ReportType.topServices:
        return 'Serviços Mais Vendidos';
      case ReportType.recurringClients:
        return 'Clientes Recorrentes';
      case ReportType.monthComparison:
        return 'Comparação Mensal';
    }
  }

  String get description {
    switch (this) {
      case ReportType.monthlyRevenue:
        return 'Análise detalhada do faturamento por mês';
      case ReportType.topServices:
        return 'Ranking dos serviços mais vendidos';
      case ReportType.recurringClients:
        return 'Clientes que mais contratam serviços';
      case ReportType.monthComparison:
        return 'Comparação entre meses diferentes';
    }
  }

  String get icon {
    switch (this) {
      case ReportType.monthlyRevenue:
        return '📊';
      case ReportType.topServices:
        return '🏆';
      case ReportType.recurringClients:
        return '👥';
      case ReportType.monthComparison:
        return '📈';
    }
  }
}

/// Monthly revenue report data
class MonthlyRevenueReport {
  final String userId;
  final DateTime month;
  final double totalRevenue;
  final int budgetCount;
  final double averageTicket;
  final Map<String, double> revenueByService; // serviceName -> revenue
  final List<DailyRevenue> dailyBreakdown;

  MonthlyRevenueReport({
    required this.userId,
    required this.month,
    required this.totalRevenue,
    required this.budgetCount,
    required this.averageTicket,
    required this.revenueByService,
    required this.dailyBreakdown,
  });

  String get formattedMonth => DateFormat('MMMM yyyy', 'pt_BR').format(month);
}

/// Daily revenue breakdown
class DailyRevenue {
  final DateTime date;
  final double revenue;
  final int budgetCount;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.budgetCount,
  });
}

/// Top services report data
class TopServicesReport {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<ServiceRanking> rankings;

  TopServicesReport({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.rankings,
  });
}

/// Service ranking entry
class ServiceRanking {
  final String serviceName;
  final int quantity;
  final double totalRevenue;
  final double percentage; // % of total revenue

  ServiceRanking({
    required this.serviceName,
    required this.quantity,
    required this.totalRevenue,
    required this.percentage,
  });
}

/// Recurring clients report data
class RecurringClientsReport {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<ClientRecurrence> clients;

  RecurringClientsReport({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.clients,
  });
}

/// Client recurrence entry
class ClientRecurrence {
  final String clientName;
  final String clientPhone;
  final int budgetCount;
  final double totalRevenue;
  final DateTime firstBudget;
  final DateTime lastBudget;

  ClientRecurrence({
    required this.clientName,
    required this.clientPhone,
    required this.budgetCount,
    required this.totalRevenue,
    required this.firstBudget,
    required this.lastBudget,
  });
}

/// Month comparison report data
class MonthComparisonReport {
  final String userId;
  final DateTime month1;
  final DateTime month2;
  final MonthStats month1Stats;
  final MonthStats month2Stats;
  final ComparisonMetrics comparison;

  MonthComparisonReport({
    required this.userId,
    required this.month1,
    required this.month2,
    required this.month1Stats,
    required this.month2Stats,
    required this.comparison,
  });
}

/// Monthly statistics
class MonthStats {
  final double totalRevenue;
  final int budgetCount;
  final double averageTicket;

  MonthStats({
    required this.totalRevenue,
    required this.budgetCount,
    required this.averageTicket,
  });
}

/// Comparison metrics between two months
class ComparisonMetrics {
  final double revenueChange; // percentage
  final int budgetCountChange; // absolute
  final double averageTicketChange; // percentage

  ComparisonMetrics({
    required this.revenueChange,
    required this.budgetCountChange,
    required this.averageTicketChange,
  });

  bool get isRevenueGrowth => revenueChange > 0;
  bool get isBudgetCountGrowth => budgetCountChange > 0;
  bool get isAverageTicketGrowth => averageTicketChange > 0;
}
