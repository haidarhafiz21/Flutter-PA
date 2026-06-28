import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class BuktiPeminjamanService {
  static Future<Map<String, dynamic>> createBukti({
    required int userId,
    required int adminId,
    required String namaPeminjam,
    required String email,
    required String alamat,
    required String fotoWajah,
    required String fotoKtp,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.buktiPeminjaman),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "admin_id": adminId,
          "nama_peminjam": namaPeminjam,
          "email": email,
          "alamat": alamat,
          "foto_wajah": fotoWajah,
          "foto_ktp": fotoKtp,
        }),
      );

      return res.body.isNotEmpty ? jsonDecode(res.body) : {};
    } catch (e) {
      return {
        "success": false,
        "message": "Gagal terhubung ke server",
      };
    }
  }

  static Future<List<dynamic>> getAllBukti() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.buktiPeminjaman),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (data is Map && data["data"] is List) return data["data"];
      if (data is List) return data;

      return [];
    } catch (e) {
      return [];
    }
  }
}