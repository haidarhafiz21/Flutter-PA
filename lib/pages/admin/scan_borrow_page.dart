import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'borrow_success_page.dart';

class ScanBorrowPage extends StatefulWidget {
  final int userId;

  const ScanBorrowPage({super.key, required this.userId});

  @override
  State<ScanBorrowPage> createState() => _ScanBorrowPageState();
}

class _ScanBorrowPageState extends State<ScanBorrowPage> {
  bool processing = false;

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// ================= SCAN =================
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (processing) return;

    final barcode = capture.barcodes.first.rawValue;

    if (barcode == null || barcode.isEmpty) return;

    final int bookId = int.tryParse(barcode) ?? 0;

    if (bookId == 0) {
      _error("Barcode tidak valid");
      return;
    }

    setState(() => processing = true);
    controller.stop();

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.scanBorrow),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": bookId,
        }),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (!mounted) return;

      /// ================= SUCCESS =================
      if (res.statusCode == 200 && data["success"] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BorrowSuccessPage(
              nama: (data["nama"] ?? "-").toString(),
              judulBuku: (data["judul"] ?? "-").toString(),
              tanggalKembali:
                  (data["tanggal_kembali"] ?? "-").toString(),
            ),
          ),
        );
        return;
      }

      /// ================= FAILED =================
      _error((data["message"] ?? "Gagal scan").toString());

    } catch (e) {
      _error("Gagal terhubung ke server");
    }

    /// 🔥 RESET SCANNER (biar bisa scan ulang)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => processing = false);
    controller.start();
  }

  /// ================= ERROR =================
  void _error(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Buku'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          /// 🔥 FRAME SCAN (BIAR UX BAGUS)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          /// 🔥 LOADING OVERLAY
          if (processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}