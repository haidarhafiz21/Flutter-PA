import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main_navigation.dart';

class PickupCountdownPage extends StatefulWidget {
  final int userId;

  const PickupCountdownPage({super.key, required this.userId});

  @override
  State<PickupCountdownPage> createState() => _PickupCountdownPageState();
}

class _PickupCountdownPageState extends State<PickupCountdownPage> {
  Timer? timer;
  Duration remaining = Duration.zero;
  bool expired = false;

  @override
  void initState() {
    super.initState();
    loadDeadline();
  }

  Future<void> goToHome() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt('user_id') ?? widget.userId;
    final nama = prefs.getString('nama') ?? "";
    final role = prefs.getString('role') ?? "peminjam";
    final fotoWajah = prefs.getString('foto_wajah') ?? "";

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigation(
          userId: userId,
          nama: nama,
          role: role,
          fotoWajah: fotoWajah,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> loadDeadline() async {
    final prefs = await SharedPreferences.getInstance();
    final deadlineMillis = prefs.getInt('borrow_pickup_deadline');

    if (deadlineMillis == null) {
      await goToHome();
      return;
    }

    final deadline = DateTime.fromMillisecondsSinceEpoch(deadlineMillis);

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = deadline.difference(DateTime.now());

      if (diff.isNegative) {
        timer?.cancel();

        if (!mounted) return;

        setState(() {
          expired = true;
          remaining = Duration.zero;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Waktu pengambilan habis")),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) goToHome();
        });
      } else {
        if (!mounted) return;
        setState(() => remaining = diff);
      }
    });
  }

  String formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Waktu Pengambilan Buku"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goToHome,
        ),
      ),
      body: Center(
        child: expired
            ? const Text(
                "Waktu habis",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text("Silakan ambil buku sebelum waktu habis"),
                  const SizedBox(height: 20),
                  Text(
                    formatTime(remaining),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}