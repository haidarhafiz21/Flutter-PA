import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminMobileLoginPage extends StatefulWidget {
  const AdminMobileLoginPage({super.key});

  @override
  State<AdminMobileLoginPage> createState() =>
      _AdminMobileLoginPageState();
}

class _AdminMobileLoginPageState extends State<AdminMobileLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await AuthService.loginAdminMobile(
        email: emailController.text,
        password: passwordController.text,
      );

      // ✅ LOGIN SUKSES
      final user = result['user'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selamat datang ${user['nama']}')),
      );

      // TODO: arahkan ke dashboard admin mobile
      // Navigator.pushReplacement(...)
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Admin Mobile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 20),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
