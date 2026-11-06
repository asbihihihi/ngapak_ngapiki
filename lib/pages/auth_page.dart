import 'package:flutter/material.dart';

import '../auth_data.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_brand_mark.dart';
import 'home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _user = AuthData.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return AuthPage(onAuthenticated: (user) => setState(() => _user = user));
    }
    return const HomePage();
  }
}

Future<void> logoutToLogin(BuildContext context) async {
  await AuthData.logout();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AuthPage()),
    (_) => false,
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onAuthenticated});

  final ValueChanged<Map<String, dynamic>>? onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _registerMode;
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _registerMode = !AuthData.hasOwner;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_registerMode) {
        await AuthData.registerOwner(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await AuthData.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      final user = AuthData.currentUser!;
      if (!mounted) return;
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!(user);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(Object error) {
    final message = error.toString();
    return message.startsWith('Bad state: ')
        ? message.substring('Bad state: '.length)
        : message.startsWith('Invalid argument(s): ')
        ? message.substring('Invalid argument(s): '.length)
        : 'Tidak dapat memproses akun: $message';
  }

  @override
  Widget build(BuildContext context) {
    final isFirstOwner = !AuthData.hasOwner;
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FarmBrandLockup(showTagline: true, markSize: 56),
                  const SizedBox(height: 34),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepGreen.withValues(alpha: .06),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _registerMode ? 'Daftar Pemilik' : 'Selamat datang',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.deepGreen,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _registerMode
                                ? 'Buat akun pemilik untuk mulai mengelola peternakan.'
                                : 'Masuk ke akun pemilik atau karyawan Anda.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.mutedText,
                                  height: 1.5,
                                ),
                          ),
                          const SizedBox(height: 26),
                          if (_registerMode) ...[
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nama pemilik',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Nama wajib diisi.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email wajib diisi.';
                              }
                              if (AuthData.validateNameAndEmail(
                                    'Nama',
                                    value,
                                  ) !=
                                  null) {
                                return 'Masukkan alamat email yang valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi wajib diisi.';
                              }
                              if (_registerMode &&
                                  AuthData.validatePassword(value) != null) {
                                return AuthData.validatePassword(value);
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _registerMode
                                        ? 'Buat akun pemilik'
                                        : 'Masuk',
                                  ),
                          ),
                          if (isFirstOwner) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Akun karyawan dibuat oleh pemilik setelah masuk.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.mutedText),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            Text(
                              'Belum memiliki akun? Hubungi pemilik peternakan.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.mutedText),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'NGAPAK NGAPIKI FARM  ·  MENGELOLA DENGAN LEBIH TERARAH',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.oliveGreen,
                      letterSpacing: .6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
