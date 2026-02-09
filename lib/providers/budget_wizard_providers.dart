import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';
import '../models/budget_model.dart';

// Current step in the wizard (0 = client, 1 = services, 2 = summary)
final currentStepProvider = StateProvider<int>((ref) => 0);

// Selected client for the budget
final selectedClientProvider = StateProvider<ClientModel?>((ref) => null);

// Selected services with quantities
final selectedServicesProvider = StateProvider<List<BudgetItem>>((ref) => []);

// Check if user can proceed to next step
final canProceedProvider = Provider<bool>((ref) {
  final step = ref.watch(currentStepProvider);
  final client = ref.watch(selectedClientProvider);
  final services = ref.watch(selectedServicesProvider);

  switch (step) {
    case 0: // Client step
      return client != null;
    case 1: // Services step
      return services.isNotEmpty;
    case 2: // Summary step
      return true;
    default:
      return false;
  }
});

// Calculate total budget amount
final budgetTotalProvider = Provider<double>((ref) {
  final items = ref.watch(selectedServicesProvider);
  return items.fold(0.0, (sum, item) => sum + item.total);
});

// Reset wizard state
void resetWizard(WidgetRef ref) {
  ref.read(currentStepProvider.notifier).state = 0;
  ref.read(selectedClientProvider.notifier).state = null;
  ref.read(selectedServicesProvider.notifier).state = [];
}
