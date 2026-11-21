import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class AuthData {
  static const ownerRole = 'pemilik';
  static const employeeRole = 'karyawan';
  static const _iterations = 30000;

  static Box get users => Hive.box('userBox');
  static Box get reports => Hive.box('dailyReportBox');
  static Box get session => Hive.box('sessionBox');
  static bool get isSupabaseAuthEnabled => SupabaseConfig.isConfigured;

  static Map<String, dynamic>? get currentUser {
    if (SupabaseConfig.isConfigured) {
      if (Supabase.instance.client.auth.currentSession == null) return null;
      final cachedUser = session.get('supabaseUser');
      return cachedUser == null ? null : Map<String, dynamic>.from(cachedUser);
    }
    final id = session.get('currentUserId');
    final user = id == null ? null : users.get(id);
    return user == null ? null : Map<String, dynamic>.from(user);
  }

  static bool get hasOwner => SupabaseConfig.isConfigured
      ? false
      : users.values.any((user) => user['role'] == ownerRole);
  static bool get canUsePos {
    final user = currentUser;
    return user?['role'] == ownerRole || user?['canUsePos'] == true;
  }

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String normalizeUsername(String username) =>
      username.trim().toLowerCase();

  static String? validateUsername(String username) {
    final normalized = normalizeUsername(username);
    return RegExp(r'^[a-z0-9._-]{3,30}$').hasMatch(normalized)
        ? null
        : 'Username 3–30 karakter; gunakan huruf kecil, angka, titik, atau tanda -/_ .';
  }

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

  static Future<bool> registerOwner({
    required String name,
    required String email,
    required String password,
    String farmName = '',
  }) async {
    final validation = validateNameAndEmail(name, email);
    if (validation != null) throw ArgumentError(validation);
    final passwordValidation = validatePassword(password);
    if (passwordValidation != null) throw ArgumentError(passwordValidation);
    if (SupabaseConfig.isConfigured) {
      if (farmName.trim().isEmpty) {
        throw ArgumentError('Nama peternakan wajib diisi.');
      }
      final response = await Supabase.instance.client.auth.signUp(
        email: normalizeEmail(email),
        password: password,
        data: {'full_name': name.trim(), 'farm_name': farmName.trim()},
      );
      final user = response.user;
      if (user == null) {
        throw StateError('Pendaftaran tidak berhasil. Silakan coba lagi.');
      }
      if (response.session == null) return false;
      await _cacheSupabaseUser(user);
      return true;
    }
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
    return true;
  }

  static Future<void> createEmployee({
    required String name,
    required String email,
    required String password,
    String? username,
    bool canUsePos = false,
  }) async {
    _requireOwner();
    if (SupabaseConfig.isConfigured) {
      final normalizedUsername = normalizeUsername(username ?? email);
      final usernameValidation = validateUsername(normalizedUsername);
      if (usernameValidation != null) {
        throw ArgumentError(usernameValidation);
      }
      final passwordValidation = validatePassword(password);
      if (passwordValidation != null) {
        throw ArgumentError(passwordValidation);
      }
      await Supabase.instance.client.functions.invoke(
        'manage-employee',
        body: {
          'action': 'create',
          'farm_id': currentUser?['farmId'],
          'name': name.trim(),
          'username': normalizedUsername,
          'password': password,
          'can_use_pos': canUsePos,
        },
      );
      return;
    }
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
      'canUsePos': canUsePos,
      ..._passwordFields(password),
      'dibuatPada': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateEmployee({
    required String id,
    required String name,
    required String email,
    String? newPassword,
    bool? canUsePos,
  }) async {
    _requireOwner();
    if (SupabaseConfig.isConfigured) {
      if (name.trim().isEmpty) throw ArgumentError('Nama wajib diisi.');
      if (newPassword != null &&
          newPassword.isNotEmpty &&
          validatePassword(newPassword) != null) {
        throw ArgumentError('Kata sandi minimal 8 karakter.');
      }
      await Supabase.instance.client.functions.invoke(
        'manage-employee',
        body: {
          'action': 'update',
          'farm_id': currentUser?['farmId'],
          'employee_id': id,
          'name': name.trim(),
          'password': newPassword ?? '',
          'can_use_pos': canUsePos,
        },
      );
      return;
    }
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
    if (canUsePos != null) updated['canUsePos'] = canUsePos;
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
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.functions.invoke(
        'manage-employee',
        body: {
          'action': 'delete',
          'farm_id': currentUser?['farmId'],
          'employee_id': id,
        },
      );
      return;
    }
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
    if (SupabaseConfig.isConfigured) {
      final normalizedIdentifier = normalizeEmail(email);
      final loginEmail = normalizedIdentifier.contains('@')
          ? normalizedIdentifier
          : '${normalizeUsername(normalizedIdentifier)}@staff.ngapak.invalid';
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: loginEmail,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw StateError('Email atau kata sandi salah.');
      }
      await _cacheSupabaseUser(user);
      return;
    }
    final user = _userForEmail(normalizeEmail(email));
    if (user == null || !_verifyPassword(password, user)) {
      throw StateError('Email atau kata sandi salah.');
    }
    await session.put('currentUserId', user['id']);
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Pemulihan kata sandi hanya tersedia untuk akun online.',
      );
    }
    final normalizedEmail = normalizeEmail(email);
    final validation = validateNameAndEmail('Nama', normalizedEmail);
    if (validation != null) throw ArgumentError('Masukkan email akun pemilik.');
    await Supabase.instance.client.auth.resetPasswordForEmail(normalizedEmail);
  }

  static Future<void> logout() async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.auth.signOut();
      await session.delete('supabaseUser');
      return;
    }
    await session.delete('currentUserId');
  }

  static Future<void> restoreSupabaseSession() async {
    if (!SupabaseConfig.isConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await _cacheSupabaseUser(user);
  }

  static Future<void> _cacheSupabaseUser(User user) async {
    final client = Supabase.instance.client;
    final profile = await client
        .from('profiles')
        .select('full_name, username, can_use_pos')
        .eq('id', user.id)
        .maybeSingle();
    final membership = await client
        .from('farm_members')
        .select('farm_id, role, farms(name)')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    if (membership == null) {
      throw StateError(
        'Akun ini belum terhubung ke peternakan. Hubungi pemilik.',
      );
    }

    final farm = membership['farms'];
    final userData = <String, dynamic>{
      'id': user.id,
      'nama':
          profile?['full_name'] ??
          user.userMetadata?['full_name'] ??
          user.email?.split('@').first ??
          'Pengguna',
      'email': user.email ?? '',
      if (profile?['username'] is String) 'username': profile!['username'],
      'canUsePos': profile?['can_use_pos'] == true,
      'role': membership['role'] == 'owner' ? ownerRole : employeeRole,
      'farmId': membership['farm_id'],
      if (farm is Map) 'farmName': farm['name'],
    };
    await session.put('supabaseUser', userData);
  }

  static Future<List<Map<String, dynamic>>> employeeList() async {
    _requireOwner();
    if (!SupabaseConfig.isConfigured) {
      return users.values
          .where((user) => user['role'] == employeeRole)
          .map((user) => Map<String, dynamic>.from(user))
          .toList()
        ..sort(
          (a, b) => '${a['nama']}'.toLowerCase().compareTo(
            '${b['nama']}'.toLowerCase(),
          ),
        );
    }

    final farmId = currentUser?['farmId'];
    if (farmId is! String || farmId.isEmpty) {
      throw StateError('Peternakan akun ini tidak ditemukan.');
    }
    final memberships = await Supabase.instance.client
        .from('farm_members')
        .select('user_id, profiles!inner(full_name, username, can_use_pos)')
        .eq('farm_id', farmId)
        .eq('role', 'employee');
    final employees =
        memberships.map((row) {
          final profile = Map<String, dynamic>.from(row['profiles'] as Map);
          return <String, dynamic>{
            'id': row['user_id'],
            'nama': profile['full_name'],
            'username': profile['username'] ?? '',
            'canUsePos': profile['can_use_pos'] == true,
          };
        }).toList()..sort(
          (a, b) => '${a['nama']}'.toLowerCase().compareTo(
            '${b['nama']}'.toLowerCase(),
          ),
        );
    return employees;
  }

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

  static String _newUserId() {
    final random = Random.secure();
    final randomPart = _encode(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    return 'USR-${DateTime.now().microsecondsSinceEpoch}-$randomPart';
  }

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
