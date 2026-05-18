import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/login_page.dart';
import 'pages/main_navigation.dart';
import 'pages/admin/main_admin_page.dart';
import 'pages/auth/register_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> cekSession() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt('user_id') ?? 0;
    final nama = prefs.getString('nama') ?? "";
    final role = prefs.getString('role') ?? "";
    final fotoWajah = prefs.getString('foto_wajah') ?? "";

    if (userId != 0 && role.isNotEmpty) {
      if (role == 'admin_mobile' || role == 'admin_web') {
        return MainAdminPage(
          nama: nama,
          userId: userId,
          fotoWajah: fotoWajah,
        );
      }

      return MainNavigation(
        userId: userId,
        nama: nama,
        role: role,
        fotoWajah: fotoWajah,
      );
    }

    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perpustakaan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xfff8f3f7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff8f3f7),
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: FutureBuilder<Widget>(
        future: cekSession(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data!;
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}