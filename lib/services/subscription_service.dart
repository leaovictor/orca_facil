import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/subscription_model.dart';
import '../core/constants/app_constants.dart';
import 'firestore_service.dart';

class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  // Product IDs
  static const Set<String> _productIds = {AppConstants.proProductId};

  // Initialize In-App Purchase
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => _handleError(error),
    );

    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    final ProductDetailsResponse response = await _iap.queryProductDetails(
      _productIds,
    );

    if (response.error != null) {
      _handleError(response.error!);
      return;
    }

    _products = response.productDetails;
  }

  // Get product details
  ProductDetails? getProProduct() {
    return _products.isEmpty
        ? null
        : _products.firstWhere(
            (product) => product.id == AppConstants.proProductId,
            orElse: () => _products.first,
          );
  }

  // Purchase Pro subscription
  Future<bool> purchaseProSubscription(String userId) async {
    if (!_isAvailable) {
      throw Exception('Loja de aplicativos não disponível');
    }

    final product = getProProduct();
    if (product == null) {
      throw Exception('Produto não encontrado');
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      throw Exception('Erro ao iniciar compra: $e');
    }
  }

  // Handle purchase updates
  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        continue;
      }

      if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        _handleError(purchaseDetails.error!);
        continue;
      }

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase (in production, verify on server)
        final bool valid = await _verifyPurchase(purchaseDetails);

        if (valid) {
          // Update Firestore subscription
          await _deliverProduct(purchaseDetails);
        }
      }

      // Mark purchase as complete
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  // Verify purchase (simplified - in production, verify on server)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In production, send purchase data to your server for verification
    // For now, we'll trust the platform's validation
    return true;
  }

  // Deliver purchased product
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      // Extract user ID (you'll need to pass this when making the purchase)
      // For now, we'll assume it's stored somewhere accessible
      // In production, you might want to pass this through the purchase payload

      // Update subscription in Firestore
      // This is a simplified version - in production, you'd need better user tracking

      // Example of updating subscription
      // await _firestoreService.updateSubscription(userId, {
      //   'tier': 'pro',
      //   'isActive': true,
      //   'expiryDate': DateTime.now().add(const Duration(days: 30)),
      // });
    } catch (e) {
      throw Exception('Erro ao processar compra: $e');
    }
  }

  // Restore purchases
  Future<void> restorePurchases(String userId) async {
    if (!_isAvailable) {
      throw Exception('Loja de aplicativos não disponível');
    }

    try {
      await _iap.restorePurchases();
    } catch (e) {
      throw Exception('Erro ao restaurar compras: $e');
    }
  }

  // Check subscription status
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final subscription = await _firestoreService.getSubscription(userId);

      if (subscription == null) return false;

      if (subscription.tier == SubscriptionTier.pro && subscription.isActive) {
        // Check if not expired
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

      if (subscription.tier == SubscriptionTier.pro) {
        return -1; // Unlimited
      }

      final remaining = AppConstants.freeBudgetLimit - subscription.budgetCount;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  // Handle errors
  void _handleError(dynamic error) {
    // Log error or show to user
    print('Purchase error: $error');
  }

  // Dispose
  void dispose() {
    _subscription?.cancel();
  }
}
