import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../widgets/kejaksaan_ui.dart';
import 'admin/main_admin_page.dart';
import 'auth/register_page.dart';
import 'main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool hidePassword = true;
  int gagalLogin = 0;

  Future<void> saveFcmToken(int userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await http.post(
        Uri.parse(ApiConfig.saveFcmToken),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "fcm_token": token,
        }),
      );
    } catch (e) {
      debugPrint("SAVE FCM TOKEN LOGIN ERROR: $e");
    }
  }

  bool isStrongPassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
    return hasMinLength && hasLetter && hasNumber && hasSymbol;
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan password wajib diisi")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 🔍 tampilkan URL yang BENAR-BENAR dipanggil
      debugPrint("LOGIN URL: ${ApiConfig.login}");

      final res = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      debugPrint("STATUS: ${res.statusCode}");
      debugPrint("BODY: ${res.body}");

      final data = jsonDecode(res.body);
      if (!mounted) return;
      setState(() => loading = false);

      if (data["success"] == true) {
        final user = data["user"];
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await prefs.setInt("user_id", user["id"]);
        await prefs.setString("nama", user["nama"] ?? "");
        await prefs.setString("email", user["email"] ?? "");
        await prefs.setString("role", user["role"] ?? "");
        await prefs.setString("foto_wajah", user["foto_wajah"] ?? "");
        await saveFcmToken(user["id"]);

        final role = (user["role"] ?? "").toString();
        if (!mounted) return;

        if (role == "admin_mobile" || role == "admin_web") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainAdminPage(
                nama: user["nama"] ?? "",
                userId: user["id"],
                fotoWajah: user["foto_wajah"] ?? "",
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainNavigation(
                userId: user["id"],
                role: role,
                nama: user["nama"] ?? "",
                fotoWajah: user["foto_wajah"] ?? "",
                email: user["email"] ?? "", // 🔧 kirim email ke MainNavigation
              ),
            ),
          );
        }
      } else {
        setState(() => gagalLogin++);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Login gagal")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        gagalLogin++;
      });
      // 🔍 TAMPILKAN ERROR ASLI (bukan "Server error" lagi)
      debugPrint("LOGIN ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ERROR ASLI: $e"),
          duration: const Duration(seconds: 12),
        ),
      );
    }
  }

  Future<void> forgotPasswordDialog() async {
    final emailResetController =
        TextEditingController(text: emailController.text.trim());
    final passwordBaruController = TextEditingController();
    bool hideNewPassword = true;
    bool loadingReset = false;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: KColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: KColors.gold),
              ),
              title: const Text(
                "Lupa Kata Sandi",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Masukkan email akun dan password baru.",
                    style: TextStyle(color: KColors.softText),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailResetController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(color: KColors.softText),
                      prefixIcon:
                          Icon(Icons.email_rounded, color: KColors.gold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordBaruController,
                    obscureText: hideNewPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Password baru",
                      hintStyle: const TextStyle(color: KColors.softText),
                      prefixIcon: const Icon(Icons.lock_reset_rounded,
                          color: KColors.gold),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hideNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: KColors.softText,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            hideNewPassword = !hideNewPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Minimal 8 karakter, harus ada huruf, angka, dan simbol.",
                    style: TextStyle(
                      color: KColors.softText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      loadingReset ? null : () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KColors.gold,
                    foregroundColor: KColors.dark,
                  ),
                  onPressed: loadingReset
                      ? null
                      : () async {
                          final email = emailResetController.text.trim();
                          final passwordBaru =
                              passwordBaruController.text.trim();
                          if (email.isEmpty || passwordBaru.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Email dan password baru wajib diisi")),
                            );
                            return;
                          }
                          if (!isStrongPassword(passwordBaru)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Password minimal 8 karakter, harus ada huruf, angka, dan simbol",
                                ),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => loadingReset = true);
                          try {
                            final res = await http.put(
                              Uri.parse(ApiConfig.forgotPassword),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({
                                "email": email,
                                "password_baru": passwordBaru,
                              }),
                            );
                            final data = jsonDecode(res.body);
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(data["message"] ?? "Selesai")),
                            );
                          } catch (e) {
                            setDialogState(() => loadingReset = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("ERROR ASLI: $e"),
                                duration: const Duration(seconds: 12),
                              ),
                            );
                          }
                        },
                  child: Text(loadingReset ? "Menyimpan..." : "Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KColors.gold.withOpacity(0.45)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: KColors.gold),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(color: KColors.softText),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showForgot = gagalLogin >= 2;
    return Scaffold(
      backgroundColor: KColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                Image.asset(
                  "assets/images/logo_kejaksaan.png",
                  width: 126,
                  height: 126,
                ),
                const SizedBox(height: 22),
                const Text(
                  "Login Perpustakaan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Kejaksaan Negeri Sumenep",
                  style: TextStyle(
                    color: KColors.softText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                inputField(
                  controller: emailController,
                  hint: "Email",
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                inputField(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock_rounded,
                  obscure: hidePassword,
                  suffix: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                      color: KColors.softText,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
                if (showForgot) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: forgotPasswordDialog,
                      child: const Text(
                        "Lupa kata sandi?",
                        style: TextStyle(
                          color: KColors.gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: KButton(
                    text: loading ? "Memproses..." : "Login",
                    icon: Icons.login_rounded,
                    loading: loading,
                    onTap: loading ? null : login,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Belum punya akun?",
                      style: TextStyle(color: KColors.softText),
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
                          color: KColors.gold,
                          fontWeight: FontWeight.w900,
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
