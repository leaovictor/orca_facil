import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/service_model.dart';
import '../models/budget_model.dart';
import '../models/subscription_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =======================
  // USER OPERATIONS
  // =======================

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromSnapshot(doc) : null);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  // =======================
  // CLIENT OPERATIONS
  // =======================

  Future<String> createClient(ClientModel client) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.clientsCollection)
          .add(client.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar cliente: $e');
    }
  }

  Future<void> updateClient(String clientId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(AppConstants.clientsCollection)
          .doc(clientId)
          .update(data);
    } catch (e) {
      throw Exception('Erro ao atualizar cliente: $e');
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await _firestore
          .collection(AppConstants.clientsCollection)
          .doc(clientId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao excluir cliente: $e');
    }
  }

  Stream<List<ClientModel>> getClientsStream(String userId) {
    return _firestore
        .collection(AppConstants.clientsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClientModel.fromSnapshot(doc))
              .toList(),
        );
  }

  Future<List<ClientModel>> searchClients(String userId, String query) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.clientsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ClientModel.fromSnapshot(doc))
          .where(
            (client) => client.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar clientes: $e');
    }
  }

  // =======================
  // SERVICE OPERATIONS
  // =======================

  Future<String> createService(ServiceModel service) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.servicesCollection)
          .add(service.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar serviço: $e');
    }
  }

  Future<void> updateService(
    String serviceId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(AppConstants.servicesCollection)
          .doc(serviceId)
          .update(data);
    } catch (e) {
      throw Exception('Erro ao atualizar serviço: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore
          .collection(AppConstants.servicesCollection)
          .doc(serviceId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao excluir serviço: $e');
    }
  }

  Stream<List<ServiceModel>> getServicesStream(String userId) {
    return _firestore
        .collection(AppConstants.servicesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServiceModel.fromSnapshot(doc))
              .toList(),
        );
  }

  // Create default services for new user
  Future<void> createDefaultServices(String userId) async {
    try {
      final batch = _firestore.batch();

      for (final serviceData in AppConstants.defaultServices) {
        final service = ServiceModel(
          id: '', // Will be set by Firestore
          userId: userId,
          name: serviceData['name'] as String,
          description: serviceData['description'] as String,
          unitPrice: (serviceData['unitPrice'] as num).toDouble(),
          createdAt: DateTime.now(),
        );

        final docRef = _firestore
            .collection(AppConstants.servicesCollection)
            .doc();
        batch.set(docRef, service.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao criar serviços padrão: $e');
    }
  }

  // =======================
  // BUDGET OPERATIONS
  // =======================

  Future<String> createBudget(BudgetModel budget) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.budgetsCollection)
          .add(budget.toMap());

      // Increment budget count in subscription
      await _firestore
          .collection(AppConstants.subscriptionsCollection)
          .doc(budget.userId)
          .update({'budgetCount': FieldValue.increment(1)});

      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar orçamento: $e');
    }
  }

  Future<void> updateBudget(String budgetId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(budgetId)
          .update(data);
    } catch (e) {
      throw Exception('Erro ao atualizar orçamento: $e');
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(budgetId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao excluir orçamento: $e');
    }
  }

  Stream<List<BudgetModel>> getBudgetsStream(String userId) {
    return _firestore
        .collection(AppConstants.budgetsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.budgetsPerPage)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BudgetModel.fromSnapshot(doc))
              .toList(),
        );
  }

  Future<List<BudgetModel>> searchBudgets(String userId, String query) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.budgetsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BudgetModel.fromSnapshot(doc))
          .where(
            (budget) =>
                budget.clientName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar orçamentos: $e');
    }
  }

  Future<int> getNextBudgetNumber(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.budgetsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('budgetNumber', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 1;
      }

      final lastBudget = BudgetModel.fromSnapshot(snapshot.docs.first);
      return lastBudget.budgetNumber + 1;
    } catch (e) {
      return 1;
    }
  }

  // =======================
  // SUBSCRIPTION OPERATIONS
  // =======================

  Future<SubscriptionModel?> getSubscription(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.subscriptionsCollection)
          .doc(userId)
          .get();
      if (doc.exists) {
        return SubscriptionModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar assinatura: $e');
    }
  }

  Stream<SubscriptionModel?> getSubscriptionStream(String userId) {
    return _firestore
        .collection(AppConstants.subscriptionsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? SubscriptionModel.fromSnapshot(doc) : null);
  }

  Future<void> updateSubscription(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.subscriptionsCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      throw Exception('Erro ao atualizar assinatura: $e');
    }
  }

  Future<void> resetBudgetCount(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.subscriptionsCollection)
          .doc(userId)
          .update({
            'budgetCount': 0,
            'periodStart': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Erro ao resetar contador de orçamentos: $e');
    }
  }

  // =======================
  // CLIENT HISTORY OPERATIONS
  // =======================

  Stream<List<BudgetModel>> getClientBudgetsStream(
    String userId,
    String clientId,
  ) {
    return _firestore
        .collection(AppConstants.budgetsCollection)
        .where('userId', isEqualTo: userId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BudgetModel.fromSnapshot(doc))
              .toList(),
        );
  }

  Future<void> updateBudgetStatus(String budgetId, BudgetStatus status) async {
    try {
      await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(budgetId)
          .update({
            'status': status.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Erro ao atualizar status do orçamento: $e');
    }
  }
}
