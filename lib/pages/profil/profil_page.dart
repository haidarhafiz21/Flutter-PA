import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/borrow_service.dart';
import '../login_page.dart';

class ProfilPage extends StatefulWidget {
  final int userId;
  final String fotoWajah;
  final ValueChanged<String>? onFotoUpdated;

  const ProfilPage({
    super.key,
    required this.userId,
    required this.fotoWajah,
    this.onFotoUpdated,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

/// 🔥 FIX BASE64
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

  @override
  void initState() {
    super.initState();
    foto = widget.fotoWajah;
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
    });
    widget.onFotoUpdated?.call(base64Image);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"]?.toString() ?? "Foto wajah diperbarui"),
      ),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 70,
              backgroundImage: foto.isNotEmpty
                  ? MemoryImage(decodeImage(foto)) // 🔥 FIX DI SINI
                  : null,
              child: foto.isEmpty
                  ? const Icon(Icons.person, size: 70)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: ambilFoto,
            child: const Text("Update Foto Wajah"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: logout,
            child: const Text("Logout"),
          )
        ],
      ),
    );
  }
}
