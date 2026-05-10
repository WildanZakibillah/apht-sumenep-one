import 'package:flutter/material.dart';
import '../../core/theme.dart';

class LaporanView extends StatefulWidget {
  const LaporanView({super.key});

  @override
  State<LaporanView> createState() => _LaporanViewState();
}

class _LaporanViewState extends State<LaporanView> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.surface, // Menggunakan surface agar lebih menyatu
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 12.0,
          ), // Padding horizontal diperlebar sedikit
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildSegmentedControl(),
              const SizedBox(height: 24),
              _buildLaporanCards(),
              SizedBox(height: 80), // Padding for Bottom Navigation
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      // Icon profile di pojok kiri atas dihapus sesuai permintaan
      title: Text(
        'Laporan',
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 24,
          fontWeight: FontWeight.w800, // Sedikit lebih tebal untuk kesan elegan
          letterSpacing: -0.5,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppTheme.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.03),
                  offset: Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari Laporan...',
                hintStyle: TextStyle(color: AppTheme.outline, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.outline),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.03),
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(Icons.filter_list_rounded),
            color: AppTheme.onPrimaryContainer,
            tooltip: 'Filter Bulan',
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(50), // Desain Pill-shape
      ),
      child: Row(
        children: [
          _buildSegmentTab('Stok', 0),
          _buildSegmentTab('Cukai', 1),
          _buildSegmentTab('Keluar', 2),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.08),
                      offset: Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaporanCards() {
    if (_selectedTabIndex == 0) {
      return Column(
        children: [
          _buildReportCard(
            date: '4 NOV 2026',
            brand: 'SAVOUR',
            type: 'SKT',
            quantity: '550',
            isi: '12',
            total: '6.600',
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            date: '4 NOV 2026',
            brand: 'SARENITY',
            type: 'SKM',
            quantity: '1.200',
            isi: '16',
            total: '19.200',
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            date: '3 NOV 2026',
            brand: 'SAVOUR',
            type: 'SKT',
            quantity: '400',
            isi: '12',
            total: '4.800',
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            date: '3 NOV 2026',
            brand: 'GALAXY',
            type: 'SKM',
            quantity: '850',
            isi: '20',
            total: '17.000',
          ),
        ],
      );
    } else if (_selectedTabIndex == 1) {
      return _buildCukaiContent();
    } else if (_selectedTabIndex == 2) {
      return _buildKeluarContent();
    } else {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Tidak ada data',
            style: TextStyle(color: AppTheme.outline),
          ),
        ),
      );
    }
  }

  Widget _buildKeluarContent() {
    return Column(
      children: [
        _buildTransactionCard(
          title: 'UD Sejahtera',
          isKredit: true,
          date: '24 Okt 2023',
          location: 'Jawa Timur',
          volume: '8.400 btg',
          nilai: 'Rp 21.000.000',
        ),
        const SizedBox(height: 16),
        _buildTransactionCard(
          title: 'CV Maju Jaya',
          isKredit: false,
          date: '23 Okt 2023',
          location: 'Jawa Tengah',
          volume: '3.200 btg',
          nilai: 'Rp 8.000.000',
        ),
        const SizedBox(height: 16),
        _buildTransactionCard(
          title: 'Toko Makmur',
          isKredit: true,
          date: '21 Okt 2023',
          location: 'Bali',
          volume: '5.500 btg',
          nilai: 'Rp 13.750.000',
        ),
      ],
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required bool isKredit,
    required String date,
    required String location,
    required String volume,
    required String nilai,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isKredit
                        ? AppTheme.secondaryContainer
                        : AppTheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    isKredit ? 'KREDIT' : 'TUNAI',
                    style: TextStyle(
                      color: isKredit
                          ? AppTheme.onSecondaryContainer
                          : AppTheme.onTertiaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppTheme.outline,
                ),
                SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '•',
                    style: TextStyle(color: AppTheme.outlineVariant),
                  ),
                ),
                Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppTheme.outline,
                ),
                SizedBox(width: 6),
                Text(
                  location,
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VOLUME',
                            style: TextStyle(
                              color: AppTheme.outline,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            volume,
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppTheme.surfaceVariant,
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(11),
                          bottomRight: Radius.circular(11),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NILAI TRANSAKSI',
                            style: TextStyle(
                              color: AppTheme.outline,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            nilai,
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildCukaiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.tertiaryFixed, AppTheme.tertiaryFixedDim],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(255, 185, 95, 0.25),
                offset: Offset(0, 10),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.onTertiaryFixed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.confirmation_number_outlined,
                      color: AppTheme.tertiary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'SISA PITA CUKAI',
                    style: TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                '300',
                style: TextStyle(
                  color: AppTheme.onTertiaryFixed,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Pembaruan terakhir: Hari ini, 08:30 WIB',
                style: TextStyle(
                  color: AppTheme.tertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32),

        // Riwayat Penggunaan
        Text(
          'Riwayat Penggunaan',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.03),
                offset: Offset(0, 6),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTimelineItem(
                isLast: false,
                isIncrease: false,
                date: '15 Okt 2023, 14:00',
                title: 'Produksi Batch #A001',
                actionLabel: 'TERPAKAI',
                actionValue: '-50',
                sisaValue: '300',
              ),
              _buildTimelineItem(
                isLast: false,
                isIncrease: true,
                date: '12 Okt 2023, 09:15',
                title: 'Penerimaan Pita Cukai Baru',
                actionLabel: 'DITERIMA',
                actionValue: '+200',
                sisaValue: '350',
              ),
              _buildTimelineItem(
                isLast: true,
                isIncrease: false,
                date: '10 Okt 2023, 16:45',
                title: 'Produksi Batch #B042',
                actionLabel: 'TERPAKAI',
                actionValue: '-150',
                sisaValue: '150',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required bool isLast,
    required bool isIncrease,
    required String date,
    required String title,
    required String actionLabel,
    required String actionValue,
    required String sisaValue,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline graphics
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned.fill(
                    top: 24,
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 2,
                        color: AppTheme.surfaceVariant,
                      ),
                    ),
                  ),
                Container(
                  margin: EdgeInsets.only(top: 2),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isIncrease
                        ? AppTheme.secondaryContainer
                        : AppTheme.errorContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.surfaceContainerLowest,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    isIncrease
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: isIncrease ? AppTheme.secondary : AppTheme.error,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      color: AppTheme.outline,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                actionLabel,
                                style: TextStyle(
                                  color: isIncrease
                                      ? AppTheme.secondary
                                      : AppTheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                actionValue,
                                style: TextStyle(
                                  color: isIncrease
                                      ? AppTheme.secondary
                                      : AppTheme.error,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppTheme.surfaceVariant,
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SISA',
                                  style: TextStyle(
                                    color: AppTheme.outline,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  sisaValue,
                                  style: TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String date,
    required String brand,
    required String type,
    required String quantity,
    required String isi,
    required String total,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        date,
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      brand,
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      type,
                      style: TextStyle(
                        color: AppTheme.outline,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  quantity,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          // Card Footer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border(
                top: BorderSide(color: AppTheme.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppTheme.outline,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Isi: $isi btg',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryFixedDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total: ',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$total btg',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
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
    );
  }
}
