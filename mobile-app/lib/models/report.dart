class Report {
  final String id;
  final String factoryId;
  final String reportMonth;
  final int totalProduction;
  final int totalOutgoing;
  final String status;
  final DateTime createdAt;
  final String createdBy;

  Report({
    required this.id,
    required this.factoryId,
    required this.reportMonth,
    required this.totalProduction,
    required this.totalOutgoing,
    required this.status,
    required this.createdAt,
    required this.createdBy,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      factoryId: json['factory_id'],
      reportMonth: json['report_month'],
      totalProduction: json['total_production'],
      totalOutgoing: json['total_outgoing'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factory_id': factoryId,
      'report_month': reportMonth,
      'total_production': totalProduction,
      'total_outgoing': totalOutgoing,
      'status': status,
      'created_by': createdBy,
    };
  }
}
