import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RequestBookService {
  static Future<Map<String, dynamic>> createRequest({
    required int userId,
    required String judulBuku,
    String? penulis,
    String? penerbit,
    String? tahunTerbit,
    String? kategoriRak,
    String? alasan,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.requestBuku),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "judul_buku": judulBuku,
          "penulis": penulis,
          "penerbit": penerbit,
          "tahun_terbit": tahunTerbit,
          "kategori_rak": kategoriRak,
          "alasan": alasan,
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

  static Future<List<dynamic>> getUserRequests(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.requestBukuUser}/$userId"),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (data is Map && data["data"] is List) return data["data"];
      if (data is List) return data;

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAdminRequests() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.requestBukuAdmin),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (data is Map && data["data"] is List) return data["data"];
      if (data is List) return data;

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> approveRequest({
    required int requestId,
    required int adminId,
    String? catatanAdmin,
  }) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiConfig.requestBuku}/$requestId/approve"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "admin_id": adminId,
          "catatan_admin": catatanAdmin,
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

  static Future<Map<String, dynamic>> rejectRequest({
    required int requestId,
    required int adminId,
    String? catatanAdmin,
  }) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiConfig.requestBuku}/$requestId/reject"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "admin_id": adminId,
          "catatan_admin": catatanAdmin,
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
}