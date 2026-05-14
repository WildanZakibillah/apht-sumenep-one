class CukaiRequest {
  final String id;
  final String? docNumber;
  final DateTime requestDate;
  final String factoryId;
  final String jenisPengajuan;
  final String lokasiPenyediaan;
  final String jenisHasilTembakau;
  final String? kodePersonalisasi;
  final String? seri;
  final String? warna;
  final num? tarifCukai;
  final num? hje;
  final int? isiPerBks;
  final int? jumlahLembar;
  final String status;
  final String createdBy;
  final DateTime createdAt;

  CukaiRequest({
    required this.id,
    this.docNumber,
    required this.requestDate,
    required this.factoryId,
    required this.jenisPengajuan,
    required this.lokasiPenyediaan,
    required this.jenisHasilTembakau,
    this.kodePersonalisasi,
    this.seri,
    this.warna,
    this.tarifCukai,
    this.hje,
    this.isiPerBks,
    this.jumlahLembar,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  factory CukaiRequest.fromJson(Map<String, dynamic> json) {
    return CukaiRequest(
      id: json['id'] as String,
      docNumber: json['doc_number'] as String?,
      requestDate: DateTime.parse(json['request_date'] as String),
      factoryId: json['factory_id'] as String,
      jenisPengajuan: json['jenis_pengajuan'] as String,
      lokasiPenyediaan: json['lokasi_penyediaan'] as String? ?? 'KPPBC',
      jenisHasilTembakau: json['jenis_hasil_tembakau'] as String,
      kodePersonalisasi: json['kode_personalisasi'] as String?,
      seri: json['seri'] as String?,
      warna: json['warna'] as String?,
      tarifCukai: json['tarif_cukai'] as num?,
      hje: json['hje'] as num?,
      isiPerBks: json['isi_per_bks'] as int?,
      jumlahLembar: json['jumlah_lembar'] as int?,
      status: json['status'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doc_number': docNumber,
      'request_date': requestDate.toIso8601String().split('T').first,
      'factory_id': factoryId,
      'jenis_pengajuan': jenisPengajuan,
      'lokasi_penyediaan': lokasiPenyediaan,
      'jenis_hasil_tembakau': jenisHasilTembakau,
      'kode_personalisasi': kodePersonalisasi,
      'seri': seri,
      'warna': warna,
      'tarif_cukai': tarifCukai,
      'hje': hje,
      'isi_per_bks': isiPerBks,
      'jumlah_lembar': jumlahLembar,
      'status': status,
      'created_by': createdBy,
    };
  }
}
