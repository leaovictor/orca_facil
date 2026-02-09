import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetItem {
  final String serviceId;
  final String serviceName;
  final String serviceDescription;
  final double unitPrice;
  final int quantity;

  BudgetItem({
    required this.serviceId,
    required this.serviceName,
    required this.serviceDescription,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceDescription': serviceDescription,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      serviceDescription: map['serviceDescription'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }
}

class BudgetModel {
  final String id;
  final String userId;
  final int budgetNumber;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String? clientAddress;
  final List<BudgetItem> items;
  final double total;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.budgetNumber,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    this.clientAddress,
    required this.items,
    required this.total,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'budgetNumber': budgetNumber,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientAddress': clientAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory BudgetModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BudgetModel(
      id: documentId,
      userId: map['userId'] ?? '',
      budgetNumber: map['budgetNumber'] ?? 0,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      clientAddress: map['clientAddress'],
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => BudgetItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (map['total'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create from Firestore DocumentSnapshot
  factory BudgetModel.fromSnapshot(DocumentSnapshot snapshot) {
    return BudgetModel.fromMap(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }

  // CopyWith method for updates
  BudgetModel copyWith({
    String? id,
    String? userId,
    int? budgetNumber,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? clientAddress,
    List<BudgetItem>? items,
    double? total,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      budgetNumber: budgetNumber ?? this.budgetNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      items: items ?? this.items,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
