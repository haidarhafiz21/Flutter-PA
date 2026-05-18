import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static int userId = 0;
  static String role = "";
  static String nama = "";

  static Future<void> save(int id, String r, String n) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
    await prefs.setString('role', r);
    await prefs.setString('nama', n);

    userId = id;
    role = r;
    nama = n;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id') ?? 0;
    role = prefs.getString('role') ?? "";
    nama = prefs.getString('nama') ?? "";
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    userId = 0;
    role = "";
    nama = "";
  }
}