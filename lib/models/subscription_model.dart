import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { free, pro }

class SubscriptionModel {
  final String userId;
  final SubscriptionTier tier;
  final DateTime? expiryDate;
  final int budgetCount; // Budgets created in current period
  final DateTime periodStart; // Start of current billing period
  final bool isActive;

  SubscriptionModel({
    required this.userId,
    required this.tier,
    this.expiryDate,
    required this.budgetCount,
    required this.periodStart,
    required this.isActive,
  });

  // Check if user has reached free tier limit
  bool get hasReachedFreeLimit =>
      tier == SubscriptionTier.free && budgetCount >= 5;

  // Check if user can create budgets
  bool get canCreateBudget {
    if (tier == SubscriptionTier.pro && isActive) {
      return true;
    }
    return !hasReachedFreeLimit;
  }

  // Check if subscription is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tier': tier.name,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'budgetCount': budgetCount,
      'periodStart': Timestamp.fromDate(periodStart),
      'isActive': isActive,
    };
  }

  // Create from Firestore document
  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      userId: map['userId'] ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      expiryDate: map['expiryDate'] != null
          ? (map['expiryDate'] as Timestamp).toDate()
          : null,
      budgetCount: map['budgetCount'] ?? 0,
      periodStart: (map['periodStart'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  // Create from Firestore DocumentSnapshot
  factory SubscriptionModel.fromSnapshot(DocumentSnapshot snapshot) {
    return SubscriptionModel.fromMap(snapshot.data() as Map<String, dynamic>);
  }

  // Create default free subscription
  factory SubscriptionModel.createFree(String userId) {
    return SubscriptionModel(
      userId: userId,
      tier: SubscriptionTier.free,
      budgetCount: 0,
      periodStart: DateTime.now(),
      isActive: true,
    );
  }

  // CopyWith method for updates
  SubscriptionModel copyWith({
    String? userId,
    SubscriptionTier? tier,
    DateTime? expiryDate,
    int? budgetCount,
    DateTime? periodStart,
    bool? isActive,
  }) {
    return SubscriptionModel(
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      expiryDate: expiryDate ?? this.expiryDate,
      budgetCount: budgetCount ?? this.budgetCount,
      periodStart: periodStart ?? this.periodStart,
      isActive: isActive ?? this.isActive,
    );
  }
}
