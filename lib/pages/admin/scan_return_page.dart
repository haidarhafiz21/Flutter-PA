import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../widgets/kejaksaan_ui.dart';

class ScanReturnPage extends StatefulWidget {
  final int peminjamanId;
  final int userId;
  final String nama;
  final String judul;
  final String barcode;

  const ScanReturnPage({
    super.key,
    required this.peminjamanId,
    required this.userId,
    required this.nama,
    required this.judul,
    required this.barcode,
  });

  @override
  State<ScanReturnPage> createState() => _ScanReturnPageState();
}

class _ScanReturnPageState extends State<ScanReturnPage>
    with SingleTickerProviderStateMixin {
  bool processing = false;

  late AnimationController lineController;

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();

    lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (processing) return;

    final barcode = capture.barcodes.first.rawValue;

    if (barcode == null || barcode.isEmpty) return;

    if (barcode != widget.barcode && barcode != widget.peminjamanId.toString()) {
      _error("Barcode tidak sesuai dengan data peminjaman");
      return;
    }

    setState(() => processing = true);
    controller.stop();

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.returnBook),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "peminjaman_id": widget.peminjamanId,
          "user_id": widget.userId,
          "barcode": barcode,
        }),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (!mounted) return;

      if (res.statusCode == 200 && data["success"] == true) {
        showSuccess(data["message"] ?? "Pengembalian berhasil");
        return;
      }

      _error((data["message"] ?? "Gagal pengembalian").toString());
    } catch (e) {
      _error("Gagal terhubung ke server");
    }

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => processing = false);
    controller.start();
  }

  void _error(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void showSuccess(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: KColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: KColors.gold),
          ),
          title: const Text(
            "Pengembalian Berhasil",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: KColors.softText,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KColors.gold,
                foregroundColor: KColors.dark,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text("Selesai"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    lineController.dispose();
    super.dispose();
  }

  Widget buildScannerFrame() {
    return Center(
      child: SizedBox(
        width: 270,
        height: 270,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: KColors.gold,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: KColors.gold.withOpacity(0.4),
                    blurRadius: 22,
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: lineController,
              builder: (_, __) {
                return Positioned(
                  top: 15 + (220 * lineController.value),
                  left: 18,
                  right: 18,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: KGradient.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopInfo() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 58, 20, 26),
        decoration: const BoxDecoration(
          gradient: KGradient.main,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(36),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_return_rounded,
              color: KColors.gold,
              size: 54,
            ),
            const SizedBox(height: 12),
            const Text(
              "Scan Pengembalian Buku",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 23,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.nama,
              style: const TextStyle(
                color: KColors.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.judul,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: KColors.softText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomInfo() {
    return Positioned(
      bottom: 90,
      left: 22,
      right: 22,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.62),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: KColors.gold.withOpacity(0.35),
          ),
        ),
        child: Column(
          children: [
            const Text(
              "Barcode yang harus discan",
              style: TextStyle(
                color: KColors.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.barcode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Pastikan barcode sesuai dengan buku yang dikembalikan.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                height: 1.4,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          buildTopInfo(),
          buildScannerFrame(),
          buildBottomInfo(),
          Positioned(
            top: 48,
            left: 10,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          if (processing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(
                  color: KColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}