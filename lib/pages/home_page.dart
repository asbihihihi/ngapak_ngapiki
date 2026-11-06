import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../auth_data.dart';
import '../farm_data.dart';
import '../operations_data.dart';
import '../pos_data.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_brand_mark.dart';
import '../widgets/farm_navigation_drawer.dart';
import 'akun_page.dart';
import 'auth_page.dart';
import 'bulk_domba_page.dart';
import 'data_domba_page.dart';
import 'gudang_page.dart';
import 'keuangan_page.dart';
import 'pos_page.dart';
import 'qr_scanner_page.dart';
import 'staff_pages.dart';
import 'batch_management_page.dart';
import 'health_management_page.dart';
import 'statistik_page.dart';
import 'weight_management_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> _asMap(dynamic raw) =>
      Map<String, dynamic>.from(raw as Map);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  Future<void> _navigate(String id, bool isOwner) async {
    if (id == 'dashboard') return;
    final Widget? page = switch (id) {
      'animals' => const DataDombaPage(),
      'qr-scanner' => const QrScannerPage(),
      'batch' => const BatchManagementPage(),
      'weight' => const WeightManagementPage(),
      'health' => const HealthManagementPage(),
      'activity' => const BulkDombaPage(),
      'livestock-sales' => const BulkDombaPage(salesOnly: true),
      'pos' => const PosPage(),
      'warehouse' => const GudangPage(),
      'finance' => const KeuanganPage(),
      'statistics' when isOwner => const StatistikPage(),
      'reports' when isOwner => const OwnerReportsPage(),
      'employees' when isOwner => const EmployeeManagementPage(),
      'worker-reports' when !isOwner => const WorkerHomePage(),
      'account' => const AkunPage(),
      _ => null,
    };
    if (page == null) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthData.currentUser ?? <String, dynamic>{};
    final isOwner = user['role'] == AuthData.ownerRole;
    final boxes = <Box>[
      Hive.box('dombaBox'),
      Hive.box('bobotDombaBox'),
      Hive.box('aktivitasDombaBox'),
      Hive.box('penjualanBox'),
      Hive.box('posSaleBox'),
      Hive.box('keuanganBox'),
      Hive.box('dailyReportBox'),
    ];
    return AnimatedBuilder(
      animation: Listenable.merge(
        boxes.map((box) => box.listenable()).toList(),
      ),
      builder: (context, _) => Scaffold(
        backgroundColor: AppTheme.warmCream,
        appBar: AppBar(
          title: Text(isOwner ? 'Ringkasan peternakan' : 'Ruang kerja'),
          actions: [
            if (isOwner)
              _NotificationButton(
                count: AuthData.unreadReportCount,
                onPressed: () => _navigate('reports', isOwner),
              ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: FarmNavigationDrawer(
          user: user,
          isOwner: isOwner,
          onSelected: (id) => _navigate(id, isOwner),
          onLogout: () => logoutToLogin(context),
        ),
        body: isOwner ? _ownerDashboard(user) : _employeeDashboard(user),
      ),
    );
  }

  Widget _ownerDashboard(Map<String, dynamic> user) {
    final animals = Hive.box('dombaBox').values.map(_asMap).toList();
    final active = animals.where((row) => !FarmData.isSold(row)).toList();
    final sold = animals.where(FarmData.isSold).length;
    final totalWeight = active.fold<double>(
      0,
      (total, row) => total + FarmData.weight(row),
    );
    final finance = FarmOperationsData.financeSummary();
    var livestockSales = 0.0;
    for (final raw in FarmData.penjualan.values) {
      if (raw is Map) {
        livestockSales +=
            FarmData.normalizeSaleTransaction(raw)['total'] as double;
      }
    }
    final sales = livestockSales + PosData.totalSales;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          _greeting(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
        ),
        const SizedBox(height: 3),
        Text(
          '${user['nama'] ?? 'Pemilik'} 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.deepGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        _FarmBanner(isOwner: true),
        const SizedBox(height: 25),
        _SectionHeading(
          title: 'Ringkasan hari ini',
          subtitle: 'Data terkini dari catatan peternakan Anda',
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 650 ? 3 : 2;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 118,
              ),
              children: [
                _MetricCard(
                  label: 'Total kambing',
                  value: '${animals.length}',
                  suffix: 'ekor',
                  icon: Icons.pets_outlined,
                  tint: AppTheme.sageGreen,
                ),
                _MetricCard(
                  label: 'Kambing aktif',
                  value: '${active.length}',
                  suffix: 'ekor',
                  icon: Icons.eco_outlined,
                  tint: const Color(0xFFEAF1E4),
                ),
                _MetricCard(
                  label: 'Terjual',
                  value: '$sold',
                  suffix: 'ekor',
                  icon: Icons.sell_outlined,
                  tint: const Color(0xFFF4EDE1),
                ),
                _MetricCard(
                  label: 'Total bobot aktif',
                  value: totalWeight.toStringAsFixed(1),
                  suffix: 'kg',
                  icon: Icons.monitor_weight_outlined,
                  tint: const Color(0xFFE9EFF0),
                ),
                _MetricCard(
                  label: 'Penjualan',
                  value: _formatCurrency(sales),
                  icon: Icons.trending_up_rounded,
                  tint: const Color(0xFFE8F0E7),
                ),
                _MetricCard(
                  label: 'Keuangan bersih',
                  value: _formatCurrency(finance['selisih'] ?? 0),
                  icon: Icons.account_balance_wallet_outlined,
                  tint: const Color(0xFFF1EDE1),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        const StatistikPage(embedded: true),
        const SizedBox(height: 26),
        _SectionHeading(
          title: 'Aktivitas terbaru',
          subtitle: 'Perubahan yang tercatat di peternakan',
        ),
        const SizedBox(height: 12),
        ..._recentEvents().map((event) => _ActivityCard(event: event)),
      ],
    );
  }

  Widget _employeeDashboard(Map<String, dynamic> user) {
    final reports = AuthData.reportsForCurrentEmployee();
    final latest = reports.isEmpty ? null : reports.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          _greeting(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
        ),
        const SizedBox(height: 3),
        Text(
          '${user['nama'] ?? 'Karyawan'} 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.deepGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        _FarmBanner(isOwner: false),
        const SizedBox(height: 22),
        _SectionHeading(
          title: 'Aktivitas Anda',
          subtitle: 'Akses cepat untuk pekerjaan hari ini',
        ),
        const SizedBox(height: 13),
        _ActionCard(
          icon: Icons.point_of_sale_outlined,
          title: 'Penjualan / POS',
          subtitle: 'Layani transaksi produk peternakan',
          onTap: () => _navigate('pos', false),
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.assignment_outlined,
          title: 'Laporan harian',
          subtitle: 'Buat laporan kegiatan atau lihat kiriman Anda',
          onTap: () => _navigate('worker-reports', false),
        ),
        const SizedBox(height: 22),
        _SectionHeading(
          title: 'Laporan terakhir',
          subtitle: 'Catatan aktivitas yang Anda kirim',
        ),
        const SizedBox(height: 12),
        if (latest == null)
          const _EmptyActivity()
        else
          _ActivityCard(
            event: _DashboardEvent(
              title: '${latest['kegiatan']}',
              detail: '${latest['waktuKegiatan'] ?? ''}',
              icon: Icons.assignment_turned_in_outlined,
              color: AppTheme.forestGreen,
              date: DateTime.tryParse('${latest['waktuKegiatan']}'),
            ),
          ),
      ],
    );
  }

  List<_DashboardEvent> _recentEvents() {
    final events = <_DashboardEvent>[];
    final animals = Hive.box('dombaBox').values;
    for (final raw in animals) {
      final animal = _asMap(raw);
      final date = DateTime.tryParse(
        '${animal['tanggalMasuk'] ?? animal['tanggal'] ?? ''}',
      );
      events.add(
        _DashboardEvent(
          title: 'Kambing ditambahkan',
          detail:
              '${animal['kode'] ?? 'Tanpa kode'} · ${animal['jenis'] ?? 'Kambing'}',
          icon: Icons.add_circle_outline,
          color: AppTheme.forestGreen,
          date: date,
        ),
      );
    }
    for (final raw in Hive.box('bobotDombaBox').values) {
      final weight = _asMap(raw);
      final note = '${weight['catatan'] ?? ''}';
      if (note.toLowerCase().contains('bobot awal')) continue;
      events.add(
        _DashboardEvent(
          title: 'Bobot kambing dicatat',
          detail:
              '${weight['kode'] ?? 'Kambing'} · ${weight['bobot'] ?? '-'} kg',
          icon: Icons.monitor_weight_outlined,
          color: const Color(0xFF597D85),
          date: DateTime.tryParse('${weight['tanggal'] ?? ''}'),
        ),
      );
    }
    for (final raw in Hive.box('aktivitasDombaBox').values) {
      final activity = _asMap(raw);
      final type = '${activity['tipe'] ?? 'Aktivitas'}';
      events.add(
        _DashboardEvent(
          title: type,
          detail: '${activity['kode'] ?? ''} · ${activity['nama'] ?? ''}',
          icon: type.toLowerCase().contains('kesehatan')
              ? Icons.health_and_safety_outlined
              : Icons.task_alt_outlined,
          color: AppTheme.oliveGreen,
          date: DateTime.tryParse('${activity['tanggal'] ?? ''}'),
        ),
      );
    }
    for (final raw in FarmData.penjualan.values) {
      if (raw is! Map) continue;
      final sale = FarmData.normalizeSaleTransaction(raw);
      events.add(
        _DashboardEvent(
          title: 'Penjualan kambing',
          detail:
              '${sale['jumlahDomba']} ekor · ${sale['namaPembeli'] ?? 'Pembeli'}',
          icon: Icons.sell_outlined,
          color: const Color(0xFFAA7650),
          date: DateTime.tryParse('${sale['tanggal'] ?? ''}'),
        ),
      );
    }
    for (final raw in Hive.box('posSaleBox').values) {
      final sale = _asMap(raw);
      events.add(
        _DashboardEvent(
          title: 'Penjualan POS',
          detail:
              '${sale['totalBeratKg'] ?? 0} kg · ${_formatCurrency((sale['total'] as num?)?.toDouble() ?? 0)}',
          icon: Icons.point_of_sale_outlined,
          color: const Color(0xFF597D85),
          date: DateTime.tryParse('${sale['tanggal'] ?? ''}'),
        ),
      );
    }
    events.sort((a, b) {
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });
    final recent = events.take(6).toList();
    return recent.isEmpty ? const [] : recent;
  }
}

class _FarmBanner extends StatelessWidget {
  const _FarmBanner({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 178),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.deepGreen, AppTheme.forestGreen],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        Positioned(
          right: -24,
          bottom: -55,
          child: Container(
            width: 185,
            height: 185,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .10),
                width: 26,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'NGAPAK NGAPIKI FARM',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFDCE9D6),
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isOwner
                          ? 'Peternakan terkelola,\nbertumbuh lebih baik.'
                          : 'Bekerja bersama,\nbertumbuh lebih baik.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Mengelola Peternakan Lebih Mudah, Lebih Terarah.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: .76),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const FarmBrandMark(
                size: 74,
                color: Colors.white,
                backgroundColor: Color(0x337F9B7C),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTheme.deepGreen,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFEDEFE9)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 20, color: AppTheme.forestGreen),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.deepGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        suffix!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
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

class _DashboardEvent {
  const _DashboardEvent({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.date,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final DateTime? date;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.event});

  final _DashboardEvent event;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFEDEFE9)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: event.color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(event.icon, color: event.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                event.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
              ),
            ],
          ),
        ),
        if (event.date != null)
          Text(
            '${event.date!.day.toString().padLeft(2, '0')}/'
            '${event.date!.month.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppTheme.mutedText, fontSize: 11),
          ),
      ],
    ),
  );
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFEDEFE9)),
    ),
    child: const Row(
      children: [
        Icon(Icons.event_note_outlined, color: AppTheme.oliveGreen),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Belum ada laporan kegiatan yang tercatat.',
            style: TextStyle(color: AppTheme.mutedText),
          ),
        ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.sageGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.forestGreen),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.oliveGreen),
          ],
        ),
      ),
    ),
  );
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Laporan karyawan',
    onPressed: onPressed,
    icon: Badge(
      isLabelVisible: count > 0,
      label: Text(count > 9 ? '9+' : '$count'),
      child: const Icon(Icons.notifications_none_rounded),
    ),
  );
}

String _formatCurrency(num value) {
  final digits = value.round().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $grouped';
}
