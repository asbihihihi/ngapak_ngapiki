import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../auth_data.dart';
import 'auth_page.dart';

class EmployeeManagementPage extends StatefulWidget {
  const EmployeeManagementPage({super.key});

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> {
  Future<void> _editEmployee([Map<String, dynamic>? employee]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EmployeeFormDialog(employee: employee),
    );
    if (saved == true && mounted) {
      _showMessage('Data karyawan berhasil disimpan.');
    }
  }

  Future<void> _deleteEmployee(Map<String, dynamic> employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus karyawan?'),
        content: Text(
          'Akun ${employee['nama']} akan dihapus. Riwayat laporan tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AuthData.deleteEmployee(employee['id'] as String);
      if (mounted) _showMessage('Akun karyawan berhasil dihapus.');
    } catch (error) {
      if (mounted) _showMessage(_messageFor(error));
    }
  }

  String _messageFor(Object error) {
    final message = error.toString();
    return message.startsWith('Bad state: ')
        ? message.substring('Bad state: '.length)
        : message.startsWith('Invalid argument(s): ')
        ? message.substring('Invalid argument(s): '.length)
        : 'Tidak dapat menyimpan data: $message';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kelola Karyawan')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _editEmployee,
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Tambah'),
    ),
    body: ValueListenableBuilder(
      valueListenable: AuthData.users.listenable(),
      builder: (context, box, _) {
        final employees =
            box.values
                .where((user) => user['role'] == AuthData.employeeRole)
                .map((user) => Map<String, dynamic>.from(user))
                .toList()
              ..sort(
                (a, b) => '${a['nama']}'.toLowerCase().compareTo(
                  '${b['nama']}'.toLowerCase(),
                ),
              );
        if (employees.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'Belum ada karyawan. Tambahkan akun agar karyawan dapat masuk dan mengirim laporan harian.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: employees.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final employee = employees[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text('${employee['nama']}'),
                subtitle: Text('${employee['email']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') _editEmployee(employee);
                    if (action == 'delete') _deleteEmployee(employee);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _EmployeeFormDialog extends StatefulWidget {
  const _EmployeeFormDialog({this.employee});

  final Map<String, dynamic>? employee;

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.employee?['nama']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.employee?['email']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final employee = widget.employee;
      if (employee == null) {
        await AuthData.createEmployee(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await AuthData.updateEmployee(
          id: employee['id'] as String,
          name: _nameController.text,
          email: _emailController.text,
          newPassword: _passwordController.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _messageFor(Object error) {
    final message = error.toString();
    return message.startsWith('Bad state: ')
        ? message.substring('Bad state: '.length)
        : message.startsWith('Invalid argument(s): ')
        ? message.substring('Invalid argument(s): '.length)
        : 'Tidak dapat menyimpan data: $message';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.employee == null ? 'Tambah karyawan' : 'Edit karyawan'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama wajib diisi.'
                  : null,
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) =>
                  AuthData.validateNameAndEmail('Nama', value ?? ''),
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.employee == null
                    ? 'Kata sandi (minimal 8 karakter)'
                    : 'Kata sandi baru (opsional)',
              ),
              validator: (value) {
                if (widget.employee == null) {
                  return AuthData.validatePassword(value ?? '');
                }
                if (value != null &&
                    value.isNotEmpty &&
                    AuthData.validatePassword(value) != null) {
                  return AuthData.validatePassword(value);
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Simpan'),
      ),
    ],
  );
}

class OwnerReportsPage extends StatefulWidget {
  const OwnerReportsPage({super.key});

  @override
  State<OwnerReportsPage> createState() => _OwnerReportsPageState();
}

class _OwnerReportsPageState extends State<OwnerReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AuthData.markReportsAsRead();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Laporan Karyawan')),
    body: ValueListenableBuilder(
      valueListenable: AuthData.reports.listenable(),
      builder: (context, _, _) {
        final reports = AuthData.dailyReports;
        if (reports.isEmpty) {
          return const Center(child: Text('Belum ada laporan harian.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _ReportCard(report: reports[index]),
        );
      },
    ),
  );
}

class WorkerHomePage extends StatelessWidget {
  const WorkerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthData.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Harian'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => logoutToLogin(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const DailyReportFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Buat laporan'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Text(
              'Halo, ${user?['nama'] ?? 'Karyawan'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Laporan saya',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: AuthData.reports.listenable(),
              builder: (context, _, _) {
                final reports = AuthData.reportsForCurrentEmployee();
                if (reports.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada laporan. Catat kegiatan seperti memberi makan kambing.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _ReportCard(report: reports[index], showEmployee: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DailyReportFormPage extends StatefulWidget {
  const DailyReportFormPage({super.key});

  @override
  State<DailyReportFormPage> createState() => _DailyReportFormPageState();
}

class _DailyReportFormPageState extends State<DailyReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _completedAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _activityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _completedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(
        () => _completedAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _completedAt.hour,
          _completedAt.minute,
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_completedAt),
    );
    if (selected != null) {
      setState(
        () => _completedAt = DateTime(
          _completedAt.year,
          _completedAt.month,
          _completedAt.day,
          selected.hour,
          selected.minute,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AuthData.saveDailyReport(
        activity: _activityController.text,
        completedAt: _completedAt,
        note: _noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan harian berhasil dikirim.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Laporan gagal disimpan: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Buat Laporan Harian')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _activityController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Kegiatan',
              hintText: 'Contoh: Memberi makan kambing',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.task_alt),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Kegiatan wajib diisi.'
                : null,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Tanggal kegiatan'),
                  subtitle: Text(_formatDate(_completedAt)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _selectDate,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Jam kegiatan'),
                  subtitle: Text(_formatTime(_completedAt)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _selectTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Tambahkan detail kegiatan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_saving ? 'Menyimpan...' : 'Kirim laporan'),
          ),
        ],
      ),
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, this.showEmployee = true});

  final Map<String, dynamic> report;
  final bool showEmployee;

  @override
  Widget build(BuildContext context) {
    final completedAt =
        DateTime.tryParse('${report['waktuKegiatan']}') ?? DateTime.now();
    final note = '${report['catatan'] ?? ''}'.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xffE4F0E7),
              child: Icon(Icons.check_circle_outline, color: Color(0xff2D6A4F)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showEmployee)
                    Text(
                      '${report['namaKaryawan'] ?? 'Karyawan'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  Text(
                    '${report['kegiatan']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(completedAt)} • ${_formatTime(completedAt)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(note, style: const TextStyle(color: Colors.black87)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

String _formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
