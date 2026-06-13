/// Represents a report from the `reports` table.
class Report {
  final String id;
  final String factoryId;
  final String period;
  final DateTime? dateSent;
  final String status;
  final String? statusLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.factoryId,
    required this.period,
    this.dateSent,
    required this.status,
    this.statusLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      factoryId: json['factory_id'],
      period: json['period'],
      dateSent: json['date_sent'] != null ? DateTime.parse(json['date_sent']) : null,
      status: json['status'] ?? 'pending',
      statusLabel: json['status_label'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factory_id': factoryId,
      'period': period,
      'date_sent': dateSent?.toIso8601String(),
      'status': status,
      'status_label': statusLabel,
    };
  }
}
