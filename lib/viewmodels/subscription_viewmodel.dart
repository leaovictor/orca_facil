import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../services/firestore_service.dart';
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
  final FirestoreService _firestoreService;

  SubscriptionViewModel(this._subscriptionService, this._firestoreService)
    : super(const AsyncValue.data(null));

  // Initialize subscription service
  Future<void> initialize() async {
    await _subscriptionService.initialize();
  }

  // Purchase Pro subscription
  Future<bool> purchaseProSubscription(String userId) async {
    state = const AsyncValue.loading();

    try {
      final result = await _subscriptionService.purchaseProSubscription(userId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // Restore purchases
  Future<void> restorePurchases(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _subscriptionService.restorePurchases(userId);
    });
  }

  // Check if user can create budget
  Future<bool> canCreateBudget(String userId) async {
    return await _subscriptionService.canCreateBudget(userId);
  }

  // Get remaining free budgets
  Future<int> getRemainingFreeBudgets(String userId) async {
    return await _subscriptionService.getRemainingFreeBudgets(userId);
  }

  // Upgrade to Pro manually (for testing or external payment)
  Future<void> upgradeToPro(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _firestoreService.updateSubscription(userId, {
        'tier': 'pro',
        'isActive': true,
        'expiryDate': DateTime.now().add(const Duration(days: 30)),
      });
    });
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
      final firestoreService = ref.watch(firestoreServiceProvider);
      final viewModel = SubscriptionViewModel(
        subscriptionService,
        firestoreService,
      );

      // Initialize on creation
      viewModel.initialize();

      return viewModel;
    });
