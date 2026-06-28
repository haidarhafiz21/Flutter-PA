import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/borrow_service.dart';
import '../../widgets/kejaksaan_ui.dart';
import '../login_page.dart';

class AdminProfilePage extends StatefulWidget {
  final String nama;
  final int userId;
  final String fotoWajah;
  final ValueChanged<String>? onFotoUpdated;

  const AdminProfilePage({
    super.key,
    required this.nama,
    required this.userId,
    required this.fotoWajah,
    this.onFotoUpdated,
  });

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final picker = ImagePicker();

  String foto = "";
  String email = "";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    foto = widget.fotoWajah;
    loadProfile();
  }

  Uint8List decodeImage(String base64String) {
    try {
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      return base64Decode(base64String);
    } catch (e) {
      return Uint8List(0);
    }
  }

  Future<void> loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/users/profile/${widget.userId}"),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data["success"] == true) {
        setState(() {
          email = data["data"]["email"] ?? "";
        });
      }
    } catch (e) {}
  }

  Future<void> ambilFoto() async {
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => loading = true);

    final bytes = await image.readAsBytes();
    final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

    final result = await BorrowService.updateFace(
      userId: widget.userId,
      fotoWajah: base64Image,
    );

    if (!mounted) return;

    setState(() => loading = false);

    if (result["success"] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"]?.toString() ?? "Gagal update foto",
          ),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foto_wajah', base64Image);

    setState(() {
      foto = base64Image;
    });

    widget.onFotoUpdated?.call(base64Image);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Foto admin berhasil diperbarui")),
    );
  }

  Future<void> updateEmailDialog() async {
    final controller = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: KColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: KColors.gold),
          ),
          title: const Text(
            "Perbarui Email",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Email baru",
              hintStyle: TextStyle(color: KColors.softText),
              prefixIcon: Icon(Icons.email_rounded, color: KColors.gold),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KColors.gold,
                foregroundColor: KColors.dark,
              ),
              onPressed: () async {
                final response = await http.put(
                  Uri.parse(ApiConfig.updateEmail),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "user_id": widget.userId,
                    "email": controller.text.trim(),
                  }),
                );

                final data = jsonDecode(response.body);

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(data["message"] ?? "Selesai")),
                );

                if (data["success"] == true) {
                  setState(() {
                    email = data["email"] ?? controller.text.trim();
                  });
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  Future<void> updatePasswordDialog() async {
    final lamaController = TextEditingController();
    final baruController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: KColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: KColors.gold),
          ),
          title: const Text(
            "Perbarui Kata Sandi",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: lamaController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Password lama",
                  hintStyle: TextStyle(color: KColors.softText),
                  prefixIcon: Icon(Icons.lock_rounded, color: KColors.gold),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: baruController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Password baru",
                  hintStyle: TextStyle(color: KColors.softText),
                  prefixIcon:
                      Icon(Icons.lock_reset_rounded, color: KColors.gold),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Minimal 8 karakter, disarankan memakai huruf, angka, dan simbol.",
                style: TextStyle(
                  color: KColors.softText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KColors.gold,
                foregroundColor: KColors.dark,
              ),
              onPressed: () async {
                final response = await http.put(
                  Uri.parse(ApiConfig.updatePassword),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "user_id": widget.userId,
                    "password_lama": lamaController.text.trim(),
                    "password_baru": baruController.text.trim(),
                  }),
                );

                final data = jsonDecode(response.body);

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(data["message"] ?? "Selesai")),
                );
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return KCard(
      margin: const EdgeInsets.only(bottom: 14),
      radius: 24,
      borderGold: true,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: KGradient.gold,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: KColors.dark, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: KColors.gold,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: KGradient.gold,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: KColors.gold.withOpacity(0.30),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: logout,
          icon: const Icon(Icons.logout_rounded, color: KColors.dark),
          label: const Text(
            "Logout",
            style: TextStyle(
              color: KColors.dark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = decodeImage(foto);

    return Scaffold(
      backgroundColor: KColors.bg,
      body: Column(
        children: [
          const KHeader(
            title: "Profil Admin",
            subtitle: "Pengelolaan akun administrator",
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                KCard(
                  radius: 32,
                  borderGold: true,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KColors.gold,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: KColors.gold.withOpacity(0.25),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 58,
                          backgroundColor: Colors.white,
                          backgroundImage: imageBytes.isNotEmpty
                              ? MemoryImage(imageBytes)
                              : null,
                          child: imageBytes.isEmpty
                              ? const Icon(
                                  Icons.admin_panel_settings,
                                  size: 58,
                                  color: KColors.green,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.nama,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email.isEmpty ? "Administrator Perpustakaan" : email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: KColors.softText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: KButton(
                          text: loading ? "Mengupload..." : "Update Foto Admin",
                          icon: Icons.camera_alt_rounded,
                          loading: loading,
                          onTap: loading ? null : ambilFoto,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                actionCard(
                  icon: Icons.email_rounded,
                  title: "Perbarui Email",
                  subtitle: "Ubah email akun admin",
                  onTap: updateEmailDialog,
                ),
                actionCard(
                  icon: Icons.lock_reset_rounded,
                  title: "Perbarui Kata Sandi",
                  subtitle: "Ganti password akun admin",
                  onTap: updatePasswordDialog,
                ),
                const SizedBox(height: 10),
                logoutButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}