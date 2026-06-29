import 'package:flutter/material.dart';
import '../core/theme.dart';

class FactoryInfoScreen extends StatelessWidget {
  final Map<String, dynamic>? factoryData;
  const FactoryInfoScreen({super.key, this.factoryData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.07) : AppTheme.outlineVariant;

    if (factoryData == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg, elevation: 0,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20)),
          title: Text('Informasi Pabrik', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: const Center(child: Text('Data pabrik tidak ditemukan')),
      );
    }

    final logoUrl = factoryData!['logo_url'] as String?;
    final latitude = factoryData!['latitude'];
    final longitude = factoryData!['longitude'];
    final coordinatesText = (latitude != null && longitude != null) ? '$latitude, $longitude' : '-';
    final isActive = factoryData!['status'] == 'active';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20)),
        title: Text('Informasi Pabrik', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  if (logoUrl != null && logoUrl.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: dividerColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.factory_outlined, color: AppTheme.primary, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: dividerColor),
                  ],
                  _buildDetailRow('Nama Pabrik', factoryData!['name'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('NPPBKC', factoryData!['nppbkc'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('NIB', factoryData!['nib'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('NPWP', factoryData!['npwp'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('Pemilik', factoryData!['owner_name'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('Direktur', factoryData!['director_name'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('Golongan', factoryData!['golongan'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('Telepon Pabrik', factoryData!['phone'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('Email Pabrik', factoryData!['email'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('Alamat', factoryData!['address'] ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('Koordinat', coordinatesText, isDark, dividerColor, true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status Pabrik', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurface, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: isActive ? const Color(0xFF10B981) : AppTheme.error, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(color: isActive ? const Color(0xFF10B981) : AppTheme.error, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, Color divider, bool hasBorder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(border: hasBorder ? Border(bottom: BorderSide(color: divider)) : null),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurface, fontSize: 14)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
