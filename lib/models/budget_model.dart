import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetItem {
  final String serviceId;
  final String serviceName;
  final String serviceDescription;
  final double basePrice;
  final double unitPrice;
  final int quantity;
  final String? difficulty;
  final double? distance;
  final String? environment;

  BudgetItem({
    required this.serviceId,
    required this.serviceName,
    required this.serviceDescription,
    required this.basePrice,
    required this.unitPrice,
    required this.quantity,
    this.difficulty,
    this.distance,
    this.environment,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceDescription': serviceDescription,
      'basePrice': basePrice,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'difficulty': difficulty,
      'distance': distance,
      'environment': environment,
    };
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      serviceDescription: map['serviceDescription'] ?? '',
      basePrice: (map['basePrice'] ?? (map['unitPrice'] ?? 0.0)).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      difficulty: map['difficulty'],
      distance: (map['distance'] as num?)?.toDouble(),
      environment: map['environment'],
    );
  }
}

enum BudgetStatus {
  pending,
  accepted,
  rejected,
  paid,
  cancelled;

  String get displayName {
    switch (this) {
      case BudgetStatus.pending:
        return 'Pendente';
      case BudgetStatus.accepted:
        return 'Aprovado';
      case BudgetStatus.rejected:
        return 'Rejeitado';
      case BudgetStatus.paid:
        return 'Pago';
      case BudgetStatus.cancelled:
        return 'Cancelado';
    }
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
  final String? clientNotes;
  final List<BudgetItem> items;
  final double total;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int validityDays;
  final int warrantyDays;
  final BudgetStatus status;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.budgetNumber,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    this.clientAddress,
    this.clientNotes,
    required this.items,
    required this.total,
    required this.createdAt,
    this.updatedAt,
    this.validityDays = 7,
    this.warrantyDays = 90,
    this.status = BudgetStatus.pending,
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
      'clientNotes': clientNotes,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'validityDays': validityDays,
      'warrantyDays': warrantyDays,
      'status': status.name,
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
      clientNotes: map['clientNotes'],
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
      validityDays: map['validityDays'] ?? 7,
      warrantyDays: map['warrantyDays'] ?? 90,
      status: BudgetStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BudgetStatus.pending,
      ),
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
    String? clientNotes,
    List<BudgetItem>? items,
    double? total,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? validityDays,
    int? warrantyDays,
    BudgetStatus? status,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      budgetNumber: budgetNumber ?? this.budgetNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      clientNotes: clientNotes ?? this.clientNotes,
      items: items ?? this.items,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      validityDays: validityDays ?? this.validityDays,
      warrantyDays: warrantyDays ?? this.warrantyDays,
      status: status ?? this.status,
    );
  }
}
