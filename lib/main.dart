import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'config/api_config.dart';
import 'pages/login_page.dart';
import 'pages/main_navigation.dart';
import 'pages/admin/main_admin_page.dart';
import 'pages/auth/register_page.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> initLocalNotification() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const initSettings = InitializationSettings(
    android: androidInit,
  );

  await localNotifications.initialize(initSettings);

  const androidChannel = AndroidNotificationChannel(
    'perpustakaan_channel',
    'Notifikasi Perpustakaan',
    description: 'Pengingat pengembalian buku perpustakaan',
    importance: Importance.max,
    playSound: true,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);
}

Future<void> showLocalNotification(RemoteMessage message) async {
  const androidDetails = AndroidNotificationDetails(
    'perpustakaan_channel',
    'Notifikasi Perpustakaan',
    channelDescription: 'Pengingat pengembalian buku perpustakaan',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const details = NotificationDetails(android: androidDetails);

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title ?? message.data['title'] ?? 'Perpustakaan',
    message.notification?.body ?? message.data['body'] ?? 'Ada notifikasi baru',
    details,
  );
}

Future<void> saveFcmTokenToBackend(int userId) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();

    if (token == null || token.isEmpty) return;

    await http.post(
      Uri.parse(ApiConfig.saveFcmToken),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "fcm_token": token,
      }),
    );
  } catch (e) {
    debugPrint("SAVE FCM TOKEN ERROR: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await initLocalNotification();

  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    showLocalNotification(message);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> cekSession() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt('user_id') ?? 0;
    var nama = prefs.getString('nama') ?? "";
    var role = prefs.getString('role') ?? "";
    var fotoWajah = prefs.getString('foto_wajah') ?? "";
    var email = prefs.getString('email') ?? "";

    if (userId != 0 && role.isNotEmpty) {
      try {
        final res = await http.get(
          Uri.parse("${ApiConfig.baseUrl}/users/profile/$userId"),
        );

        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        if (data is Map && data["success"] == true && data["data"] is Map) {
          final user = Map<String, dynamic>.from(data["data"]);
          nama = (user["nama_lengkap"] ?? nama).toString();
          role = (user["role"] ?? role).toString();
          fotoWajah = (user["foto_wajah"] ?? fotoWajah).toString();
          email = (user["email"] ?? email).toString();

          await prefs.setString('nama', nama);
          await prefs.setString('role', role);
          await prefs.setString('foto_wajah', fotoWajah);
          await prefs.setString('email', email);
        }
      } catch (e) {
        debugPrint("REFRESH SESSION PROFILE ERROR: $e");
      }

      await saveFcmTokenToBackend(userId);

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
        email: email,
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
        scaffoldBackgroundColor: const Color(0xff031F19),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff031F19),
          foregroundColor: Colors.white,
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
