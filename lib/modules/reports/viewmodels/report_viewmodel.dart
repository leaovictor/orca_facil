import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/report_service.dart';
import '../models/report_models.dart';

// Report Service Provider
final reportServiceProvider = Provider<ReportService>((ref) => ReportService());

// Monthly Revenue Report Provider
final monthlyRevenueReportProvider =
    FutureProvider.family<MonthlyRevenueReport, MonthlyRevenueParams>((
      ref,
      params,
    ) async {
      final service = ref.watch(reportServiceProvider);
      return await service.generateMonthlyRevenueReport(
        userId: params.userId,
        month: params.month,
      );
    });

// Top Services Report Provider
final topServicesReportProvider =
    FutureProvider.family<TopServicesReport, PeriodParams>((ref, params) async {
      final service = ref.watch(reportServiceProvider);
      return await service.generateTopServicesReport(
        userId: params.userId,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
      );
    });

// Recurring Clients Report Provider
final recurringClientsReportProvider =
    FutureProvider.family<RecurringClientsReport, PeriodParams>((
      ref,
      params,
    ) async {
      final service = ref.watch(reportServiceProvider);
      return await service.generateRecurringClientsReport(
        userId: params.userId,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
      );
    });

// Month Comparison Report Provider
final monthComparisonReportProvider =
    FutureProvider.family<MonthComparisonReport, ComparisonParams>((
      ref,
      params,
    ) async {
      final service = ref.watch(reportServiceProvider);
      return await service.generateMonthComparisonReport(
        userId: params.userId,
        month1: params.month1,
        month2: params.month2,
      );
    });

// Parameter classes for providers
class MonthlyRevenueParams {
  final String userId;
  final DateTime month;

  MonthlyRevenueParams({required this.userId, required this.month});

  @override
  bool operator ==(Object other) =>
      other is MonthlyRevenueParams &&
      other.userId == userId &&
      other.month == month;

  @override
  int get hashCode => Object.hash(userId, month);
}

class PeriodParams {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;

  PeriodParams({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
  });

  @override
  bool operator ==(Object other) =>
      other is PeriodParams &&
      other.userId == userId &&
      other.periodStart == periodStart &&
      other.periodEnd == periodEnd;

  @override
  int get hashCode => Object.hash(userId, periodStart, periodEnd);
}

class ComparisonParams {
  final String userId;
  final DateTime month1;
  final DateTime month2;

  ComparisonParams({
    required this.userId,
    required this.month1,
    required this.month2,
  });

  @override
  bool operator ==(Object other) =>
      other is ComparisonParams &&
      other.userId == userId &&
      other.month1 == month1 &&
      other.month2 == month2;

  @override
  int get hashCode => Object.hash(userId, month1, month2);
}
