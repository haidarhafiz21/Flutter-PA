import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/borrow_service.dart';
import 'main_navigation.dart';
import 'admin/main_admin_page.dart';
import 'auth/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;

  Future<void> login() async {
    if (isLoading) return;

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan password wajib diisi")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await BorrowService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => isLoading = false);

      if (res['success'] == true) {
        final user = res['user'];

        final prefs = await SharedPreferences.getInstance();

        await prefs.clear();
        await prefs.setInt('user_id', user['id']);
        await prefs.setString('nama', user['nama']);
        await prefs.setString('role', user['role']);
        await prefs.setString('foto_wajah', user['foto_wajah'] ?? "");

        if (user['role'] == 'admin_mobile' || user['role'] == 'admin_web') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainAdminPage(
                nama: user['nama'],
                userId: user['id'],
                fotoWajah: user['foto_wajah'] ?? "",
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainNavigation(
                userId: user['id'],
                nama: user['nama'],
                role: user['role'],
                fotoWajah: user['foto_wajah'] ?? "",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Login gagal")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan koneksi")),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// 🔥 INPUT FIELD FIX (PASSWORD SUDAH BENAR)
  Widget inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool password = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: password ? !showPassword : false, // ✅ FIX DISINI
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xff355f57)),
        suffixIcon: password
            ? IconButton(
                icon: Icon(
                  showPassword
                      ? Icons.visibility   // 👁 terlihat
                      : Icons.visibility_off, // 🙈 tersembunyi
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => showPassword = !showPassword);
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f3f7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo_kejaksaan.png',
                  height: 110,
                ),

                const SizedBox(height: 18),

                const Text(
                  "Login Perpustakaan",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1f2937),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Kejaksaan Negeri Sumenep",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 34),

                inputField(
                  controller: emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 16),

                inputField(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  password: true,
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffff7043),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Belum punya akun?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Color(0xffff7043),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}