import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import 'top_services_detail_screen.dart';

class TopServicesScreen extends ConsumerStatefulWidget {
  const TopServicesScreen({super.key});

  @override
  ConsumerState<TopServicesScreen> createState() => _TopServicesScreenState();
}

class _TopServicesScreenState extends ConsumerState<TopServicesScreen> {
  late DateTime _periodStart;
  late DateTime _periodEnd;

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _periodStart = DateTime(now.year, now.month, 1);
    _periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  Future<void> _selectPeriod() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _periodStart, end: _periodEnd),
      helpText: 'Selecione o período',
      builder: (context, child) {
        return child!;
      },
    );

    if (picked != null) {
      setState(() {
        _periodStart = picked.start;
        _periodEnd = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
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

    final params = PeriodParams(
      userId: user.uid,
      periodStart: _periodStart,
      periodEnd: _periodEnd,
    );

    final reportAsync = ref.watch(topServicesReportProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços Mais Vendidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectPeriod,
            tooltip: 'Mudar período',
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => TopServicesDetailScreen(report: report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Período: ${DateFormat('dd/MM/yy').format(_periodStart)} - ${DateFormat('dd/MM/yy').format(_periodEnd)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _selectPeriod,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Alterar'),
            ),
          ],
        ),
      ),
    );
  }
}
