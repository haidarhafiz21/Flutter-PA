import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class AuthService {

  // =========================
  // REGISTER
  // =========================

  static Future<Map<String, dynamic>?> register({
    required String nama,
    required String alamat,
    required String email,
    required String password,
    required String foto,
  }) async {

    try {

      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": nama,
          "alamat": alamat,
          "email": email,
          "password": password,
          "foto": foto
        }),
      );

      print("REGISTER RESPONSE: ${res.body}");

      return jsonDecode(res.body);

    } catch (e) {

      print("REGISTER ERROR: $e");
      return null;

    }

  }

  // =========================
  // LOGIN
  // =========================

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {

    try {

      final res = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password
        }),
      );

      print("LOGIN STATUS: ${res.statusCode}");
      print("LOGIN RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return jsonDecode(res.body);
      }

    } catch (e) {

      print("LOGIN ERROR: $e");
      return null;

    }

  }

}