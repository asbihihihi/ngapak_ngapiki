import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

class AuthData {
  static const ownerRole = 'pemilik';
  static const employeeRole = 'karyawan';
  static const _iterations = 30000;

  static Box get users => Hive.box('userBox');
  static Box get reports => Hive.box('dailyReportBox');
  static Box get session => Hive.box('sessionBox');

  static Map<String, dynamic>? get currentUser {
    final id = session.get('currentUserId');
    final user = id == null ? null : users.get(id);
    return user == null ? null : Map<String, dynamic>.from(user);
  }

  static bool get hasOwner =>
      users.values.any((user) => user['role'] == ownerRole);

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String? validateNameAndEmail(String name, String email) {
    if (name.trim().isEmpty) return 'Nama wajib diisi.';
    final normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail.contains('@') ||
        !normalizedEmail
            .substring(normalizedEmail.indexOf('@'))
            .contains('.')) {
      return 'Masukkan alamat email yang valid.';
    }
    return null;
  }

  static String? validatePassword(String password) =>
      password.length < 8 ? 'Kata sandi minimal 8 karakter.' : null;

  static Future<void> registerOwner({
    required String name,
    required String email,
    required String password,
  }) async {
    final validation = validateNameAndEmail(name, email);
    if (validation != null) throw ArgumentError(validation);
    final passwordValidation = validatePassword(password);
    if (passwordValidation != null) throw ArgumentError(passwordValidation);
    if (hasOwner) throw StateError('Akun pemilik sudah terdaftar.');
    final normalizedEmail = normalizeEmail(email);
    if (_userForEmail(normalizedEmail) != null) {
      throw StateError('Email sudah terdaftar.');
    }
    final id = _newUserId();

    await users.put(id, {
      'id': id,
      'nama': name.trim(),
      'email': normalizedEmail,
      'role': ownerRole,
      ..._passwordFields(password),
      'dibuatPada': DateTime.now().toIso8601String(),
    });
    await login(email: email, password: password);
  }

  static Future<void> createEmployee({
    required String name,
    required String email,
    required String password,
  }) async {
    _requireOwner();
    final validation = validateNameAndEmail(name, email);
    if (validation != null) throw ArgumentError(validation);
    final passwordValidation = validatePassword(password);
    if (passwordValidation != null) throw ArgumentError(passwordValidation);
    final normalizedEmail = normalizeEmail(email);
    if (_userForEmail(normalizedEmail) != null) {
      throw StateError('Email sudah terdaftar.');
    }
    final id = _newUserId();

    await users.put(id, {
      'id': id,
      'nama': name.trim(),
      'email': normalizedEmail,
      'role': employeeRole,
      ..._passwordFields(password),
      'dibuatPada': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateEmployee({
    required String id,
    required String name,
    required String email,
    String? newPassword,
  }) async {
    _requireOwner();
    final existing = users.get(id);
    if (existing == null || existing['role'] != employeeRole) {
      throw StateError('Akun karyawan tidak ditemukan.');
    }
    final validation = validateNameAndEmail(name, email);
    if (validation != null) throw ArgumentError(validation);
    if (newPassword != null && newPassword.isNotEmpty) {
      final passwordValidation = validatePassword(newPassword);
      if (passwordValidation != null) throw ArgumentError(passwordValidation);
    }

    final normalizedEmail = normalizeEmail(email);
    final conflictingUser = _userForEmail(normalizedEmail);
    if (conflictingUser != null && conflictingUser['id'] != id) {
      throw StateError('Email sudah digunakan akun lain.');
    }
    final updated = Map<String, dynamic>.from(existing)
      ..['nama'] = name.trim()
      ..['email'] = normalizedEmail
      ..['diperbaruiPada'] = DateTime.now().toIso8601String();
    if (newPassword != null && newPassword.isNotEmpty) {
      updated
        ..remove('salt')
        ..remove('passwordHash')
        ..addAll(_passwordFields(newPassword));
    }
    await users.put(id, updated);
  }

  static Future<void> deleteEmployee(String id) async {
    _requireOwner();
    final employee = users.get(id);
    if (employee == null || employee['role'] != employeeRole) {
      throw StateError('Akun karyawan tidak ditemukan.');
    }
    await users.delete(id);
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final user = _userForEmail(normalizeEmail(email));
    if (user == null || !_verifyPassword(password, user)) {
      throw StateError('Email atau kata sandi salah.');
    }
    await session.put('currentUserId', user['id']);
  }

  static Future<void> logout() => session.delete('currentUserId');

  static Future<String> saveDailyReport({
    required String activity,
    required DateTime completedAt,
    String note = '',
  }) async {
    final user = currentUser;
    if (user == null || user['role'] != employeeRole) {
      throw StateError('Hanya karyawan yang dapat mengirim laporan.');
    }
    final normalizedActivity = activity.trim();
    if (normalizedActivity.isEmpty) {
      throw ArgumentError('Kegiatan wajib diisi.');
    }
    final id = 'RPT-${DateTime.now().microsecondsSinceEpoch}';
    await reports.put(id, {
      'id': id,
      'karyawanId': user['id'],
      'namaKaryawan': user['nama'],
      'kegiatan': normalizedActivity,
      'waktuKegiatan': completedAt.toIso8601String(),
      'catatan': note.trim(),
      'dibuatPada': DateTime.now().toIso8601String(),
    });
    return id;
  }

  static List<Map<String, dynamic>> get dailyReports {
    final rows = reports.values
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    rows.sort(
      (a, b) => '${b['waktuKegiatan']}'.compareTo('${a['waktuKegiatan']}'),
    );
    return rows;
  }

  static List<Map<String, dynamic>> reportsForCurrentEmployee() {
    final id = currentUser?['id'];
    return dailyReports.where((report) => report['karyawanId'] == id).toList();
  }

  static int get unreadReportCount {
    final seen = List<String>.from(
      session.get('seenReportIds', defaultValue: []),
    );
    return dailyReports.where((report) => !seen.contains(report['id'])).length;
  }

  static Future<void> markReportsAsRead() async {
    final seen = List<String>.from(
      session.get('seenReportIds', defaultValue: []),
    );
    seen.addAll(dailyReports.map((report) => report['id'] as String));
    await session.put('seenReportIds', seen.toSet().toList());
  }

  static void _requireOwner() {
    if (currentUser?['role'] != ownerRole) {
      throw StateError('Hanya pemilik yang dapat mengelola karyawan.');
    }
  }

  static Map<String, dynamic>? _userForEmail(String email) {
    for (final value in users.values) {
      final user = Map<String, dynamic>.from(value);
      if (user['email'] == email) return user;
    }
    return null;
  }

  static String _newUserId() =>
      'USR-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';

  static Map<String, String> _passwordFields(String password) {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    return {'salt': _encode(salt), 'passwordHash': _derive(password, salt)};
  }

  static bool _verifyPassword(String password, dynamic user) {
    final salt = _decode('${user['salt']}');
    return _derive(password, salt) == user['passwordHash'];
  }

  static String _derive(String password, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final derived = List<int>.from(block);
    for (var iteration = 1; iteration < _iterations; iteration++) {
      block = hmac.convert(block).bytes;
      for (var index = 0; index < derived.length; index++) {
        derived[index] ^= block[index];
      }
    }
    return _encode(derived);
  }

  static String _encode(List<int> bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  static List<int> _decode(String value) => [
    for (var index = 0; index < value.length; index += 2)
      int.parse(value.substring(index, index + 2), radix: 16),
  ];
}
