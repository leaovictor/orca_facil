import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/service_model.dart';
import 'auth_viewmodel.dart';

// Services Stream Provider
final servicesProvider = StreamProvider.family<List<ServiceModel>, String>((
  ref,
  userId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getServicesStream(userId);
});

// Auto services stream provider (gets userId automatically)
final servicesStreamProvider = StreamProvider.autoDispose<List<ServiceModel>>((
  ref,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(authStateProvider);

  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }

  return firestoreService.getServicesStream(user.uid);
});

// Service ViewModel for CRUD operations
class ServiceViewModel extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;

  ServiceViewModel(this._firestoreService) : super(const AsyncValue.data(null));

  // Create service
  Future<String?> createService({
    required String userId,
    required String name,
    required String description,
    required double unitPrice,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ServiceModel(
        id: '', // Will be set by Firestore
        userId: userId,
        name: name,
        description: description,
        unitPrice: unitPrice,
        createdAt: DateTime.now(),
      );

      final serviceId = await _firestoreService.createService(service);
      state = const AsyncValue.data(null);
      return serviceId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  // Update service
  Future<void> updateService({
    required String serviceId,
    required String name,
    required String description,
    required double unitPrice,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _firestoreService.updateService(serviceId, {
        'name': name,
        'description': description,
        'unitPrice': unitPrice,
      });
    });
  }

  // Delete service
  Future<void> deleteService(String serviceId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _firestoreService.deleteService(serviceId);
    });
  }
}

// Service ViewModel Provider
final serviceViewModelProvider =
    StateNotifierProvider<ServiceViewModel, AsyncValue<void>>((ref) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return ServiceViewModel(firestoreService);
    });
