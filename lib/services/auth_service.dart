import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class AuthService {

  // =============================
  // REGISTER
  // =============================
  static Future<Map<String, dynamic>?> register({
    required String nama,
    required String alamat,
    required String email,
    required String password,
    required String foto,
  }) async {

    try {

      final response = await http.post(
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

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER RESPONSE: ${response.body}");

      return jsonDecode(response.body);

    } catch (e) {

      print("REGISTER ERROR: $e");
      return null;

    }

  }


  // =============================
  // LOGIN
  // =============================
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {

    try {

      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password
        }),
      );

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN RESPONSE: ${response.body}");

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        return data;

      } else {

        return {
          "message": "Email atau password salah"
        };

      }

    } catch (e) {

      print("LOGIN ERROR: $e");

      return {
        "message": "Tidak dapat terhubung ke server"
      };

    }

  }

}