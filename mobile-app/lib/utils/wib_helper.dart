/// Helper untuk konversi waktu ke WIB (UTC+7)
/// Gunakan class ini untuk semua operasi waktu di aplikasi
class WIB {
  /// Offset WIB dari UTC (7 jam)
  static const Duration offset = Duration(hours: 7);

  /// Mendapatkan waktu sekarang dalam WIB
  static DateTime now() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(offset);
  }

  /// Konversi DateTime UTC ke WIB
  static DateTime fromUtc(DateTime utcTime) {
    final utc = utcTime.isUtc ? utcTime : utcTime.toUtc();
    return utc.add(offset);
  }

  /// Konversi DateTime (dari Supabase/ISO string) ke WIB
  static DateTime parse(String isoString) {
    final utcTime = DateTime.parse(isoString).toUtc();
    return utcTime.add(offset);
  }

  /// Format tanggal WIB ke string ISO (hanya tanggal: yyyy-MM-dd)
  static String toDateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Format tanggal WIB ke string ISO lengkap dengan timezone +07:00
  static String toIsoString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final s = date.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s+07:00';
  }

  /// Mendapatkan tanggal hari ini dalam WIB (tanpa jam)
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}
