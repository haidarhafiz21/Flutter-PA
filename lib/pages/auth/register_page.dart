import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../widgets/kejaksaan_ui.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final namaController = TextEditingController();
  final alamatController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  File? imageFile;
  String? fotoBase64;

  File? ktpFile;
  String? ktpBase64;

  bool loading = false;
  bool hidePassword = true;

  final ImagePicker picker = ImagePicker();

  @override
  void dispose() {
    namaController.dispose();
    alamatController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool isStrongPassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    return hasMinLength && hasLetter && hasNumber && hasSymbol;
  }

  Future<void> ambilFoto() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

        setState(() {
          imageFile = File(image.path);
          fotoBase64 = base64Image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka kamera")),
      );
    }
  }

  Future<void> ambilKtp() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

        setState(() {
          ktpFile = File(image.path);
          ktpBase64 = base64Image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memilih foto KTP")),
      );
    }
  }

  Future<void> register() async {
    final nama = namaController.text.trim();
    final alamat = alamatController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (nama.isEmpty ||
        alamat.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        fotoBase64 == null ||
        ktpBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua data wajib diisi, termasuk foto wajah dan KTP"),
        ),
      );
      return;
    }

    if (!email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format email tidak valid")),
      );
      return;
    }

    if (!isStrongPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password minimal 8 karakter, harus ada huruf, angka, dan simbol",
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": nama,
          "alamat": alamat,
          "email": email,
          "password": password,
          "foto": fotoBase64,
          "foto_ktp": ktpBase64,
        }),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (!mounted) return;

      setState(() => loading = false);

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registrasi berhasil, silakan login")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Registrasi gagal")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );
    }
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
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

  Widget fotoWajahBox() {
    return Center(
      child: GestureDetector(
        onTap: ambilFoto,
        child: Container(
          width: 134,
          height: 134,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: KGradient.gold,
            boxShadow: [
              BoxShadow(
                color: KColors.gold.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: CircleAvatar(
            backgroundColor: KColors.card,
            backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
            child: imageFile == null
                ? const Icon(
                    Icons.camera_alt_rounded,
                    color: KColors.gold,
                    size: 42,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget fotoKtpBox() {
    return InkWell(
      onTap: ambilKtp,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: KColors.gold.withOpacity(0.45),
          ),
        ),
        child: ktpFile == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.badge_rounded,
                    color: KColors.gold,
                    size: 46,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Upload Foto KTP",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Pilih foto KTP dari galeri",
                    style: TextStyle(
                      color: KColors.softText,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  ktpFile!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Registrasi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            fotoWajahBox(),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Ambil foto wajah untuk data akun",
                style: TextStyle(color: KColors.softText),
              ),
            ),
            const SizedBox(height: 24),
            fotoKtpBox(),
            const SizedBox(height: 24),
            inputField(
              controller: namaController,
              hint: "Nama lengkap",
              icon: Icons.person_rounded,
            ),
            inputField(
              controller: alamatController,
              hint: "Alamat",
              icon: Icons.location_on_rounded,
            ),
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
            const Text(
              "Password minimal 8 karakter, harus ada huruf, angka, dan simbol.",
              style: TextStyle(
                color: KColors.softText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            KButton(
              text: loading ? "Mendaftarkan..." : "Daftar",
              icon: Icons.person_add_alt_1_rounded,
              loading: loading,
              onTap: loading ? null : register,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}