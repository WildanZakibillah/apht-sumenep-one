import '../utils/wib_helper.dart';

class OutgoingGood {
  final String id;
  final DateTime transactionDate;
  final String customerName;
  final String? regionId;
  final String productId;
  final String factoryId;
  final int volume;
  final num totalValue;
  final String paymentMethod;
  final String createdBy;
  final DateTime createdAt;

  OutgoingGood({
    required this.id,
    required this.transactionDate,
    required this.customerName,
    this.regionId,
    required this.productId,
    required this.factoryId,
    required this.volume,
    required this.totalValue,
    required this.paymentMethod,
    required this.createdBy,
    required this.createdAt,
  });

  factory OutgoingGood.fromJson(Map<String, dynamic> json) {
    return OutgoingGood(
      id: json['id'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      customerName: json['customer_name'] as String,
      regionId: json['region_id'] as String?,
      productId: json['product_id'] as String,
      factoryId: json['factory_id'] as String,
      volume: json['volume'] as int,
      totalValue: json['total_value'] as num,
      paymentMethod: json['payment_method'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_date': WIB.toDateString(transactionDate),
      'customer_name': customerName,
      'region_id': regionId,
      'product_id': productId,
      'factory_id': factoryId,
      'volume': volume,
      'total_value': totalValue,
      'payment_method': paymentMethod,
      'created_by': createdBy,
    };
  }
}
