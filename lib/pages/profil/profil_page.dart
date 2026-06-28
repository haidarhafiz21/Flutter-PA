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

class ProfilPage extends StatefulWidget {
  final int userId;
  final String fotoWajah;
  final String email; // 🔧 baru
  final String nama;  // 🔧 baru
  final ValueChanged<String>? onFotoUpdated;

  const ProfilPage({
    super.key,
    required this.userId,
    required this.fotoWajah,
    this.email = "", // 🔧 default "" agar aman / tidak error
    this.nama = "",  // 🔧 default "" agar aman / tidak error
    this.onFotoUpdated,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
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

class _ProfilPageState extends State<ProfilPage> {
  final picker = ImagePicker();
  String foto = "";
  String email = "";
  bool loadingEmail = false; // 🔧
  Uint8List fotoBytes = Uint8List(0); // 🔧 simpan hasil decode foto sekali saja

  @override
  void initState() {
    super.initState();
    foto = widget.fotoWajah;
    fotoBytes = decodeImage(foto);        // 🔧 decode SEKALI di awal (tidak di build)
    email = widget.email;                 // 🔧 email langsung dari constructor → TANPA KEDIP
    loadingEmail = widget.email.isEmpty;  // 🔧 "Memuat…" hanya jika email belum ada
    loadProfile();                        // refresh diam-diam dari server
  }

  Future<void> loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/users/profile/${widget.userId}"),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        final emailServer = data["data"]["email"] ?? "";
        if (!mounted) return;
        setState(() {
          email = emailServer;
          loadingEmail = false;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', emailServer);
      } else {
        if (!mounted) return;
        setState(() => loadingEmail = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingEmail = false); // 🔧 jangan menggantung
    }
  }

  Future<void> ambilFoto() async {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

    final result = await BorrowService.updateFace(
      userId: widget.userId,
      fotoWajah: base64Image,
    );

    if (!mounted) return;

    if (result["success"] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]?.toString() ?? "Gagal update foto"),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foto_wajah', base64Image);

    setState(() {
      foto = base64Image;
      fotoBytes = decodeImage(base64Image); // 🔧 perbarui foto yang tersimpan
    });

    widget.onFotoUpdated?.call(base64Image);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"]?.toString() ?? "Foto berhasil diperbarui"),
      ),
    );
  }

  Future<void> updateEmailDialog() async {
    final controller = TextEditingController(text: email);
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: KColors.card,
          title: const Text(
            "Perbarui Email",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: "Masukkan email baru",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: KColors.gold),
              onPressed: () async {
                final response = await http.put(
                  Uri.parse("${ApiConfig.baseUrl}/users/update-email"),
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
                  SnackBar(content: Text(data["message"])),
                );
                if (data["success"] == true) {
                  final emailBaru = data["email"] ?? controller.text.trim();
                  setState(() {
                    email = emailBaru;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('email', emailBaru);
                }
              },
              child: const Text(
                "Simpan",
                style: TextStyle(color: KColors.dark),
              ),
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
          title: const Text(
            "Perbarui Password",
            style: TextStyle(color: Colors.white),
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
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: baruController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Password baru",
                  hintStyle: TextStyle(color: Colors.grey),
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
              style: ElevatedButton.styleFrom(backgroundColor: KColors.gold),
              onPressed: () async {
                final response = await http.put(
                  Uri.parse("${ApiConfig.baseUrl}/users/update-password"),
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
                  SnackBar(content: Text(data["message"])),
                );
              },
              child: const Text(
                "Simpan",
                style: TextStyle(color: KColors.dark),
              ),
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
              color: KColors.gold.withOpacity(0.35),
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
          icon: const Icon(
            Icons.logout_rounded,
            color: KColors.dark,
          ),
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
    final imageBytes = fotoBytes; // 🔧 pakai foto yang sudah di-decode, tidak decode ulang
    final namaTampil =
        widget.nama.isEmpty ? "Pengguna Perpustakaan" : widget.nama; // 🔧 nama asli

    return Scaffold(
      backgroundColor: KColors.bg,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
            decoration: const BoxDecoration(
              gradient: KGradient.main,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(34),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: KColors.gold),
                  ),
                  child: Image.asset("assets/images/logo_kejaksaan.png"),
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Profil Pengguna",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Informasi akun perpustakaan",
                        style: TextStyle(
                          color: KColors.softText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                KCard(
                  borderGold: true,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: KColors.gold,
                        child: CircleAvatar(
                          radius: 51,
                          backgroundImage:
                              imageBytes.isNotEmpty ? MemoryImage(imageBytes) : null,
                          child: imageBytes.isEmpty
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        namaTampil, // 🔧 menampilkan nama asli user
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loadingEmail
                            ? "Memuat…"
                            : (email.isEmpty ? "Email belum tersedia" : email),
                        style: const TextStyle(color: KColors.softText),
                      ),
                      const SizedBox(height: 22),
                      KButton(
                        text: "Update Foto Wajah",
                        icon: Icons.camera_alt_rounded,
                        onTap: ambilFoto,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                KCard(
                  borderGold: true,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: KColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.email_rounded,
                        color: KColors.gold,
                      ),
                    ),
                    title: const Text(
                      "Perbarui Email",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      "Ubah email akun pengguna",
                      style: TextStyle(color: KColors.softText),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: KColors.gold,
                      size: 18,
                    ),
                    onTap: updateEmailDialog,
                  ),
                ),
                KCard(
                  borderGold: true,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: KColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: KColors.gold,
                      ),
                    ),
                    title: const Text(
                      "Perbarui Kata Sandi",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      "Ganti password akun pengguna",
                      style: TextStyle(color: KColors.softText),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: KColors.gold,
                      size: 18,
                    ),
                    onTap: updatePasswordDialog,
                  ),
                ),
                const SizedBox(height: 8),
                logoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}