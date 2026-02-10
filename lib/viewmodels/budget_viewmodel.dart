import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../services/whatsapp_service.dart';
import '../services/notification_service.dart';
import '../models/budget_model.dart';
import '../models/client_model.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import 'auth_viewmodel.dart';

// PDF Service Provider
final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());

// WhatsApp Service Provider
final whatsappServiceProvider = Provider<WhatsAppService>(
  (ref) => WhatsAppService(),
);

// Budgets Stream Provider
final budgetsProvider = StreamProvider.family<List<BudgetModel>, String>((
  ref,
  userId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getBudgetsStream(userId);
});

// Budget ViewModel for creating new budgets
class BudgetViewModel extends StateNotifier<AsyncValue<BudgetModel?>> {
  final FirestoreService _firestoreService;
  final PdfService _pdfService;
  final NotificationService _notificationService;

  BudgetViewModel(
    this._firestoreService,
    this._pdfService,
    this._notificationService,
  ) : super(const AsyncValue.data(null));

  // Create new budget
  Future<String?> createBudget({
    required String userId,
    required ClientModel client,
    required List<BudgetItem> items,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Calculate total
      final total = items.fold<double>(0, (sum, item) => sum + item.total);

      // Verify subscription limits
      final subscription = await _firestoreService.getSubscription(userId);
      if (subscription != null && !subscription.canCreateBudget) {
        throw Exception(
          'Limite de orçamentos atingido no plano Gratuito.\nFaça um upgrade para criar orçamentos ilimitados.',
        );
      }

      // Get next budget number
      final budgetNumber = await _firestoreService.getNextBudgetNumber(userId);

      // Create budget model
      final budget = BudgetModel(
        id: '', // Will be set by Firestore
        userId: userId,
        budgetNumber: budgetNumber,
        clientId: client.id,
        clientName: client.name,
        clientPhone: client.phone,
        clientAddress: client.address,
        clientNotes: client.notes,
        items: items,
        total: total,
        createdAt: DateTime.now(),
        validityDays: 7, // Default
        warrantyDays: 90, // Default
      );

      // Save to Firestore
      final budgetId = await _firestoreService.createBudget(budget);

      // Update state with created budget
      final createdBudget = budget.copyWith(id: budgetId);
      state = AsyncValue.data(createdBudget);

      return budgetId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  // Generate and share PDF
  Future<void> generateAndSharePdf({
    required BudgetModel budget,
    required UserModel user,
    required SubscriptionModel subscription,
  }) async {
    try {
      final pdfBytes = await _pdfService.generateBudgetPdf(
        budget: budget,
        user: user,
        subscription: subscription,
      );

      final fileName = 'Orcamento_${budget.budgetNumber}';
      await _pdfService.sharePdf(pdfBytes, fileName);
    } catch (e) {
      throw Exception('Erro ao gerar PDF: $e');
    }
  }

  // Generate and preview PDF
  Future<void> generateAndPreviewPdf({
    required BudgetModel budget,
    required UserModel user,
    required SubscriptionModel subscription,
  }) async {
    try {
      final pdfBytes = await _pdfService.generateBudgetPdf(
        budget: budget,
        user: user,
        subscription: subscription,
      );

      await _pdfService.printPdf(pdfBytes);
    } catch (e) {
      throw Exception('Erro ao gerar preview do PDF: $e');
    }
  }

  // Search budgets
  Future<List<BudgetModel>> searchBudgets(String userId, String query) async {
    try {
      return await _firestoreService.searchBudgets(userId, query);
    } catch (e) {
      throw Exception('Erro ao buscar orçamentos: $e');
    }
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    state = const AsyncValue.loading();
    await AsyncValue.guard(() async {
      await _firestoreService.deleteBudget(budgetId);
    });
    state = const AsyncValue.data(null);
  }

  // Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }

  // Send budget via WhatsApp
  Future<bool> sendBudgetViaWhatsApp({
    required BudgetModel budget,
    required UserModel user,
    String? pdfUrl,
  }) async {
    try {
      final whatsappService = WhatsAppService();
      return await whatsappService.sendBudgetViaWhatsApp(
        phone: budget.clientPhone,
        budget: budget,
        user: user,
        pdfUrl: pdfUrl,
      );
    } catch (e) {
      return false;
    }
  }

  // Update budget status
  Future<void> updateBudgetStatus(
    String budgetId,
    BudgetStatus status, {
    BudgetModel? budget,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _firestoreService.updateBudgetStatus(budgetId, status);

      // Notify if paid
      if (status == BudgetStatus.paid && budget != null) {
        await _notificationService.showPaymentNotification(
          clientName: budget.clientName,
          amount: budget.total,
        );
      }

      return null;
    });
  }
}

// Budget ViewModel Provider
final budgetViewModelProvider =
    StateNotifierProvider<BudgetViewModel, AsyncValue<BudgetModel?>>((ref) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      final pdfService = ref.watch(pdfServiceProvider);
      final notificationService = ref.watch(notificationServiceProvider);

      return BudgetViewModel(firestoreService, pdfService, notificationService);
    });
