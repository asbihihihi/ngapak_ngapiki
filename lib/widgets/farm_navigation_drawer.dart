import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'farm_brand_mark.dart';

class FarmNavigationItem {
  const FarmNavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    this.section,
  });

  final String id;
  final String label;
  final IconData icon;
  final String? section;
}

class FarmNavigationDrawer extends StatelessWidget {
  const FarmNavigationDrawer({
    super.key,
    required this.user,
    required this.isOwner,
    required this.onSelected,
    required this.onLogout,
  });

  final Map<String, dynamic> user;
  final bool isOwner;
  final ValueChanged<String> onSelected;
  final VoidCallback onLogout;

  static const ownerItems = <FarmNavigationItem>[
    FarmNavigationItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.grid_view_rounded,
    ),
    FarmNavigationItem(
      id: 'animals',
      label: 'Data Kambing',
      icon: Icons.pets_outlined,
      section: 'PETERNAKAN',
    ),
    FarmNavigationItem(
      id: 'qr-scanner',
      label: 'Pindai QR Kambing',
      icon: Icons.qr_code_scanner_rounded,
    ),
    FarmNavigationItem(
      id: 'batch',
      label: 'Batch Pembelian',
      icon: Icons.inventory_2_outlined,
    ),
    FarmNavigationItem(
      id: 'weight',
      label: 'Bobot Kambing',
      icon: Icons.monitor_weight_outlined,
    ),
    FarmNavigationItem(
      id: 'health',
      label: 'Kesehatan',
      icon: Icons.health_and_safety_outlined,
    ),
    FarmNavigationItem(
      id: 'activity',
      label: 'Aktivitas Peternakan',
      icon: Icons.task_alt_outlined,
    ),
    FarmNavigationItem(
      id: 'livestock-sales',
      label: 'Penjualan Kambing',
      icon: Icons.sell_outlined,
      section: 'OPERASIONAL',
    ),
    FarmNavigationItem(
      id: 'pos',
      label: 'Penjualan / POS',
      icon: Icons.point_of_sale_outlined,
    ),
    FarmNavigationItem(
      id: 'warehouse',
      label: 'Inventori Gudang',
      icon: Icons.warehouse_outlined,
    ),
    FarmNavigationItem(
      id: 'finance',
      label: 'Keuangan',
      icon: Icons.account_balance_wallet_outlined,
    ),
    FarmNavigationItem(
      id: 'statistics',
      label: 'Dashboard Statistik',
      icon: Icons.query_stats_rounded,
    ),
    FarmNavigationItem(
      id: 'reports',
      label: 'Laporan Karyawan',
      icon: Icons.assignment_outlined,
      section: 'TIM',
    ),
    FarmNavigationItem(
      id: 'employees',
      label: 'Kelola Karyawan',
      icon: Icons.groups_outlined,
    ),
    FarmNavigationItem(
      id: 'account',
      label: 'Pengaturan & Akun',
      icon: Icons.settings_outlined,
      section: 'AKUN',
    ),
  ];

  static const employeeItems = <FarmNavigationItem>[
    FarmNavigationItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.grid_view_rounded,
    ),
    FarmNavigationItem(
      id: 'pos',
      label: 'Penjualan / POS',
      icon: Icons.point_of_sale_outlined,
      section: 'OPERASIONAL',
    ),
    FarmNavigationItem(
      id: 'worker-reports',
      label: 'Laporan Harian',
      icon: Icons.assignment_outlined,
    ),
    FarmNavigationItem(
      id: 'account',
      label: 'Akun Saya',
      icon: Icons.person_outline,
      section: 'AKUN',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = isOwner ? ownerItems : employeeItems;
    return Drawer(
      width: 310,
      backgroundColor: AppTheme.warmCream,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FarmBrandLockup(markSize: 48),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.sageGreen,
                          foregroundColor: AppTheme.forestGreen,
                          child: Text(
                            '${user['nama'] ?? 'U'}'
                                .trim()
                                .characters
                                .first
                                .toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user['nama'] ?? 'Pengguna'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.darkText,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isOwner ? 'Pemilik peternakan' : 'Karyawan',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mutedText,
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
            const Divider(height: 1, indent: 20, endIndent: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                children: [
                  for (final item in items) ...[
                    if (item.section != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 7),
                        child: Text(
                          item.section!,
                          style: const TextStyle(
                            color: AppTheme.oliveGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      leading: Icon(item.icon, size: 21),
                      title: Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      iconColor: AppTheme.forestGreen,
                      textColor: AppTheme.deepGreen,
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(item.id);
                      },
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFB5473B),
                ),
                title: const Text(
                  'Keluar',
                  style: TextStyle(
                    color: Color(0xFFB5473B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
