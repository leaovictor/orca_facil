import '../models/subscription_model.dart';
import '../core/constants/app_constants.dart';
import 'firestore_service.dart';

class SubscriptionService {
  final FirestoreService _firestoreService = FirestoreService();

  // Check subscription status
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final subscription = await _firestoreService.getSubscription(userId);

      if (subscription == null) return false;

      // Both Pro and Premium are considered "active subscriptions"
      if ((subscription.tier == SubscriptionTier.pro ||
              subscription.tier == SubscriptionTier.premium) &&
          subscription.isActive) {
        // Check if not expired
        if (subscription.expiryDate == null) return true;
        return !subscription.isExpired;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if user has Premium (highest tier) access
  Future<bool> hasPremiumAccess(String userId) async {
    try {
      final subscription = await _firestoreService.getSubscription(userId);

      if (subscription == null) return false;

      if (subscription.tier == SubscriptionTier.premium &&
          subscription.isActive) {
        if (subscription.expiryDate == null) return true;
        return !subscription.isExpired;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if user can create budget
  Future<bool> canCreateBudget(String userId) async {
    try {
      final subscription = await _firestoreService.getSubscription(userId);
      return subscription?.canCreateBudget ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get remaining free budgets
  Future<int> getRemainingFreeBudgets(String userId) async {
    try {
      final subscription = await _firestoreService.getSubscription(userId);

      if (subscription == null) return 0;

      // Pro and Premium have unlimited budgets
      if (subscription.tier == SubscriptionTier.pro ||
          subscription.tier == SubscriptionTier.premium) {
        return -1; // Unlimited
      }

      final remaining = AppConstants.freeBudgetLimit - subscription.budgetCount;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  // Initialize
  Future<void> initialize() async {
    // Initialization no longer requires IAP setup for Stripe web-based flow
  }

  // Dispose
  void dispose() {
    // No more stream to cancel
  }
}
