import 'package:flutter/material.dart';

import '../auth_data.dart';
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
    final canRegister = isFirstOwner;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xffE4F0E7),
                      child: Icon(
                        Icons.agriculture,
                        size: 40,
                        color: Color(0xff2D6A4F),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _registerMode ? 'Daftar Pemilik' : 'Selamat Datang',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registerMode
                          ? 'Buat akun pemilik untuk mulai mengelola peternakan.'
                          : 'Masuk dengan akun pemilik atau karyawan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    if (_registerMode) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama pemilik',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi.';
                        }
                        if (AuthData.validateNameAndEmail('Nama', value) !=
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
                        border: const OutlineInputBorder(),
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
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff2D6A4F),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_registerMode ? 'Daftar' : 'Masuk'),
                    ),
                    if (canRegister) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Akun karyawan dibuat oleh pemilik setelah masuk.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                    if (!isFirstOwner) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada akun? Hubungi pemilik peternakan untuk dibuatkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
