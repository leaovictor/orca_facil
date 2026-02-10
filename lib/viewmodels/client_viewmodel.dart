import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';
import '../models/budget_model.dart';
import '../services/firestore_service.dart';
import 'auth_viewmodel.dart';

// Provider para o ClientViewModel
final clientViewModelProvider =
    StateNotifierProvider<ClientViewModel, AsyncValue<void>>((ref) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return ClientViewModel(firestoreService);
    });

// Stream provider para listar todos os clientes do usuário
final clientsStreamProvider = StreamProvider.autoDispose<List<ClientModel>>((
  ref,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(authStateProvider);

  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }

  return firestoreService.getClientsStream(user.uid);
});

// Stream provider para listar orçamentos de um cliente específico
final clientBudgetsStreamProvider = StreamProvider.family
    .autoDispose<List<BudgetModel>, String>((ref, clientId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      final authState = ref.watch(authStateProvider);

      final user = authState.value;
      if (user == null) {
        return Stream.value([]);
      }

      return firestoreService.getClientBudgetsStream(user.uid, clientId);
    });

class ClientViewModel extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;

  ClientViewModel(this._firestoreService) : super(const AsyncValue.data(null));

  // Create client
  Future<String?> createClient({
    required String userId,
    required String name,
    required String phone,
    String? address,
    String? notes,
  }) async {
    state = const AsyncValue.loading();

    try {
      final client = ClientModel(
        id: '', // Will be set by Firestore
        userId: userId,
        name: name,
        phone: phone,
        address: address,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final clientId = await _firestoreService.createClient(client);
      state = const AsyncValue.data(null);
      return clientId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  // Update client
  Future<void> updateClient({
    required String clientId,
    required String name,
    required String phone,
    String? address,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _firestoreService.updateClient(clientId, {
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
      });
    });
  }

  // Delete client
  Future<void> deleteClient(String clientId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _firestoreService.deleteClient(clientId);
    });
  }
}
