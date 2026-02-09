import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../models/subscription_model.dart';
import 'auth_viewmodel.dart';

// Subscription Service Provider
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Subscription Stream Provider
final subscriptionProvider = StreamProvider.family<SubscriptionModel?, String>((
  ref,
  userId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSubscriptionStream(userId);
});

// Subscription ViewModel for managing subscriptions
class SubscriptionViewModel extends StateNotifier<AsyncValue<void>> {
  final SubscriptionService _subscriptionService;

  SubscriptionViewModel(this._subscriptionService)
    : super(const AsyncValue.data(null));

  // Initialize subscription service
  Future<void> initialize() async {
    await _subscriptionService.initialize();
  }

  // Check if user can create budget
  Future<bool> canCreateBudget(String userId) async {
    return await _subscriptionService.canCreateBudget(userId);
  }

  // Get remaining free budgets
  Future<int> getRemainingFreeBudgets(String userId) async {
    return await _subscriptionService.getRemainingFreeBudgets(userId);
  }

  // Dispose
  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }
}

// Subscription ViewModel Provider
final subscriptionViewModelProvider =
    StateNotifierProvider<SubscriptionViewModel, AsyncValue<void>>((ref) {
      final subscriptionService = ref.watch(subscriptionServiceProvider);
      final viewModel = SubscriptionViewModel(subscriptionService);

      // Initialize on creation
      viewModel.initialize();

      return viewModel;
    });
