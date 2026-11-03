import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ngapak_farm/auth_data.dart';
import 'package:ngapak_farm/pages/auth_page.dart';
import 'package:ngapak_farm/pages/staff_pages.dart';

void main() {
  late Directory testDirectory;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp('farm-auth-test-');
    Hive.init(testDirectory.path);
    await Hive.openBox('userBox');
    await Hive.openBox('dailyReportBox');
    await Hive.openBox('sessionBox');
  });

  setUp(() async {
    await AuthData.users.clear();
    await AuthData.reports.clear();
    await AuthData.session.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets('shows first-owner registration before an account exists', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));

    expect(find.text('Daftar Pemilik'), findsOneWidget);
    expect(
      find.text('Akun karyawan dibuat oleh pemilik setelah masuk.'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the employee form open and shows duplicate email errors', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await AuthData.registerOwner(
        name: 'Pemilik Farm',
        email: 'pemilik@example.com',
        password: 'rahasia123',
      );
      await AuthData.createEmployee(
        name: 'Karyawan',
        email: 'karyawan@example.com',
        password: 'karyawan123',
      );
    });
    await tester.pumpWidget(const MaterialApp(home: EmployeeManagementPage()));
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Karyawan Baru');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'karyawan@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'baru12345');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Email sudah terdaftar.'), findsOneWidget);
    expect(find.text('Tambah karyawan'), findsOneWidget);
    expect(AuthData.users, hasLength(2));
  });

  test('registers the first owner and rejects another public owner', () async {
    await AuthData.registerOwner(
      name: 'Pemilik Farm',
      email: 'pemilik@example.com',
      password: 'rahasia123',
    );

    expect(AuthData.currentUser?['role'], AuthData.ownerRole);
    final owner = AuthData.users.values.single as Map;
    expect(owner['password'], isNull);
    expect(owner['passwordHash'], isNotNull);
    await expectLater(
      AuthData.registerOwner(
        name: 'Pemilik Lain',
        email: 'lain@example.com',
        password: 'rahasia123',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('owner manages employees and employee sends a daily report', () async {
    await AuthData.registerOwner(
      name: 'Pemilik Farm',
      email: 'pemilik@example.com',
      password: 'rahasia123',
    );
    await AuthData.createEmployee(
      name: 'Budi',
      email: 'budi@example.com',
      password: 'karyawan123',
    );
    final employeeId =
        AuthData.users.values.singleWhere(
              (user) => user['role'] == AuthData.employeeRole,
            )['id']
            as String;
    await AuthData.logout();
    await AuthData.login(email: 'budi@example.com', password: 'karyawan123');
    await AuthData.saveDailyReport(
      activity: 'Memberi makan kambing',
      completedAt: DateTime(2026, 11, 3, 8, 30),
      note: 'Semua kambing sudah diberi pakan.',
    );

    expect(AuthData.reportsForCurrentEmployee(), hasLength(1));
    await AuthData.logout();
    await AuthData.login(email: 'pemilik@example.com', password: 'rahasia123');
    expect(AuthData.dailyReports.single['namaKaryawan'], 'Budi');
    expect(AuthData.unreadReportCount, 1);
    await AuthData.markReportsAsRead();
    expect(AuthData.unreadReportCount, 0);

    await AuthData.updateEmployee(
      id: employeeId,
      name: 'Budi Santoso',
      email: 'budi.baru@example.com',
    );
    expect(AuthData.users.get(employeeId)['nama'], 'Budi Santoso');
    await AuthData.logout();
    await AuthData.login(
      email: 'budi.baru@example.com',
      password: 'karyawan123',
    );
    expect(AuthData.reportsForCurrentEmployee(), hasLength(1));
    await AuthData.logout();
    await AuthData.login(email: 'pemilik@example.com', password: 'rahasia123');
    await AuthData.deleteEmployee(employeeId);
    expect(AuthData.users.containsKey(employeeId), isFalse);
    expect(AuthData.dailyReports, hasLength(1));
  });

  test('rejects invalid credentials and employee account management', () async {
    await AuthData.registerOwner(
      name: 'Pemilik Farm',
      email: 'pemilik@example.com',
      password: 'rahasia123',
    );
    await AuthData.createEmployee(
      name: 'Budi',
      email: 'budi@example.com',
      password: 'karyawan123',
    );
    final employeeId =
        AuthData.users.values.singleWhere(
              (user) => user['role'] == AuthData.employeeRole,
            )['id']
            as String;
    await AuthData.logout();
    await expectLater(
      AuthData.login(email: 'budi@example.com', password: 'salah123'),
      throwsA(isA<StateError>()),
    );
    await AuthData.login(email: 'budi@example.com', password: 'karyawan123');
    await expectLater(
      AuthData.createEmployee(
        name: 'Ani',
        email: 'ani@example.com',
        password: 'karyawan456',
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      AuthData.updateEmployee(
        id: employeeId,
        name: 'Nama Baru',
        email: 'pemilik@example.com',
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      AuthData.saveDailyReport(activity: ' ', completedAt: DateTime.now()),
      throwsA(isA<ArgumentError>()),
    );
  });
}
