import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import 'month_comparison_detail_screen.dart';

class MonthComparisonScreen extends ConsumerStatefulWidget {
  const MonthComparisonScreen({super.key});

  @override
  ConsumerState<MonthComparisonScreen> createState() =>
      _MonthComparisonScreenState();
}

class _MonthComparisonScreenState extends ConsumerState<MonthComparisonScreen> {
  late DateTime _month1;
  late DateTime _month2;

  @override
  void initState() {
    super.initState();
    // Default: current month vs previous month
    final now = DateTime.now();
    _month2 = DateTime(now.year, now.month, 1);
    _month1 = DateTime(now.year, now.month - 1, 1);
  }

  Future<void> _selectMonth1() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month1,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Selecione o primeiro mês',
    );

    if (picked != null) {
      setState(() {
        _month1 = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  Future<void> _selectMonth2() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month2,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Selecione o segundo mês',
    );

    if (picked != null) {
      setState(() {
        _month2 = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não encontrado')),
      );
    }

    final params = ComparisonParams(
      userId: user.uid,
      month1: _month1,
      month2: _month2,
    );

    final reportAsync = ref.watch(monthComparisonReportProvider(params));

    return reportAsync.when(
      data: (report) => MonthComparisonDetailScreen(
        report: report,
        onSelectMonth1: _selectMonth1,
        onSelectMonth2: _selectMonth2,
        month1: _month1,
        month2: _month2,
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Comparação entre Meses')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar relatório',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
