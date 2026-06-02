import '../utils/wib_helper.dart';

class Production {
  final String id;
  final String docNumber;
  final DateTime docDate;
  final String productId;
  final String factoryId;
  final String jenis;
  final String merek;
  final num hje;
  final String? bahanKemasan;
  final int isi;
  final String satuan;
  final int jumlahKemasan;
  final int jumlahIsi;
  final String createdBy;
  final DateTime createdAt;

  Production({
    required this.id,
    required this.docNumber,
    required this.docDate,
    required this.productId,
    required this.factoryId,
    required this.jenis,
    required this.merek,
    required this.hje,
    this.bahanKemasan,
    required this.isi,
    required this.satuan,
    required this.jumlahKemasan,
    required this.jumlahIsi,
    required this.createdBy,
    required this.createdAt,
  });

  factory Production.fromJson(Map<String, dynamic> json) {
    return Production(
      id: json['id'] as String,
      docNumber: json['doc_number'] as String,
      docDate: DateTime.parse(json['doc_date'] as String),
      productId: json['product_id'] as String,
      factoryId: json['factory_id'] as String,
      jenis: json['jenis'] as String,
      merek: json['merek'] as String,
      hje: json['hje'] as num,
      bahanKemasan: json['bahan_kemasan'] as String?,
      isi: json['isi'] as int,
      satuan: json['satuan'] as String,
      jumlahKemasan: json['jumlah_kemasan'] as int,
      jumlahIsi: json['jumlah_isi'] as int,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doc_number': docNumber,
      'doc_date': WIB.toDateString(docDate),
      'product_id': productId,
      'factory_id': factoryId,
      'jenis': jenis,
      'merek': merek,
      'hje': hje,
      'bahan_kemasan': bahanKemasan,
      'isi': isi,
      'satuan': satuan,
      'jumlah_kemasan': jumlahKemasan,
      'jumlah_isi': jumlahIsi,
      'created_by': createdBy,
    };
  }
}
