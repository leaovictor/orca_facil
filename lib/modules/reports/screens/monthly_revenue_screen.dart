import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import 'monthly_revenue_detail_screen.dart';

class MonthlyRevenueScreen extends ConsumerStatefulWidget {
  const MonthlyRevenueScreen({super.key});

  @override
  ConsumerState<MonthlyRevenueScreen> createState() =>
      _MonthlyRevenueScreenState();
}

class _MonthlyRevenueScreenState extends ConsumerState<MonthlyRevenueScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Default to current month
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final initialDate = _selectedMonth;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Selecione o mês',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
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

    final params = MonthlyRevenueParams(
      userId: user.uid,
      month: _selectedMonth,
    );

    final reportAsync = ref.watch(monthlyRevenueReportProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faturamento Mensal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
            tooltip: 'Mudar mês',
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => MonthlyRevenueDetailScreen(report: report),
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
                'Período: ${DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _selectMonth,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Alterar'),
            ),
          ],
        ),
      ),
    );
  }
}
