import 'package:flutter/material.dart';

import '../auth_data.dart';
import 'auth_page.dart';

class AkunPage extends StatelessWidget {
  const AkunPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthData.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 42,
            child: Icon(Icons.person_outline, size: 44),
          ),
          const SizedBox(height: 12),
          Text(
            '${user?['nama'] ?? 'Pengguna'}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            user?['role'] == AuthData.ownerRole ? 'Pemilik' : 'Karyawan',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          if (user?['email'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${user!['email']}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Tentang aplikasi'),
              subtitle: Text('Ngapak Ngapiki Farm'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar'),
              onTap: () => logoutToLogin(context),
            ),
          ),
        ],
      ),
    );
  }
}
