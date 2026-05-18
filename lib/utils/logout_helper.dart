import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/login_page.dart';

class LogoutHelper {
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // 🧹 HAPUS SEMUA SESSION
    await prefs.clear();

    // 🔁 KEMBALI KE LOGIN (TUTUP SEMUA PAGE)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
