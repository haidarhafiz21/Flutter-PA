import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;

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

  final ImagePicker picker = ImagePicker();

  /// ================= AMBIL FOTO =================
  Future<void> ambilFoto() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        /// 🔥 WAJIB ADA PREFIX
        final base64Image =
            "data:image/jpeg;base64,${base64Encode(bytes)}";

        setState(() {
          imageFile = File(image.path);
          fotoBase64 = base64Image;
        });

        print("FOTO OK | LENGTH: ${fotoBase64!.length}");
      }
    } catch (e) {
      print("ERROR CAMERA: $e");
    }
  }

  /// ================= REGISTER =================
  Future<void> register() async {
    if (namaController.text.isEmpty ||
        alamatController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        fotoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua data wajib diisi")),
      );
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": namaController.text.trim(),
          "alamat": alamatController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "foto": fotoBase64,
        }),
      );

      final data = jsonDecode(res.body);

      print("REGISTER RESP: $data");

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registrasi berhasil")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Gagal")),
        );
      }
    } catch (e) {
      print("ERROR REGISTER: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrasi")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            GestureDetector(
              onTap: ambilFoto,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    imageFile != null ? FileImage(imageFile!) : null,
                child: imageFile == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            TextField(controller: namaController, decoration: const InputDecoration(labelText: "Nama")),
            TextField(controller: alamatController, decoration: const InputDecoration(labelText: "Alamat")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: register,
              child: const Text("Daftar"),
            )
          ],
        ),
      ),
    );
  }
}