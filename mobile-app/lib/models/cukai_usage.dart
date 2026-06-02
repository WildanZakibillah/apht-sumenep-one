import '../utils/wib_helper.dart';

class CukaiUsage {
  final String id;
  final String allocationId;
  final String factoryId;
  final DateTime usageDate;
  final int usedAmount;
  final int addedAmount;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;

  CukaiUsage({
    required this.id,
    required this.allocationId,
    required this.factoryId,
    required this.usageDate,
    required this.usedAmount,
    required this.addedAmount,
    this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  factory CukaiUsage.fromJson(Map<String, dynamic> json) {
    return CukaiUsage(
      id: json['id'] as String,
      allocationId: json['allocation_id'] as String,
      factoryId: json['factory_id'] as String,
      usageDate: DateTime.parse(json['usage_date'] as String),
      usedAmount: json['used_amount'] as int,
      addedAmount: json['added_amount'] as int,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allocation_id': allocationId,
      'factory_id': factoryId,
      'usage_date': WIB.toDateString(usageDate),
      'used_amount': usedAmount,
      'added_amount': addedAmount,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}
