import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../widgets/kejaksaan_ui.dart';

import 'borrow_success_page.dart';

class ScanBorrowPage extends StatefulWidget {
  final int userId;

  const ScanBorrowPage({
    super.key,
    required this.userId,
  });

  @override
  State<ScanBorrowPage> createState() =>
      _ScanBorrowPageState();
}

class _ScanBorrowPageState
    extends State<ScanBorrowPage>
    with SingleTickerProviderStateMixin {

  bool processing = false;

  late AnimationController lineController;

  final MobileScannerController controller =
      MobileScannerController(
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

  Future<void> _onDetect(
    BarcodeCapture capture,
  ) async {

    if (processing) return;

    final barcode =
        capture.barcodes.first.rawValue;

    if (barcode == null || barcode.isEmpty) {
      return;
    }

    final int bookId =
        int.tryParse(barcode) ?? 0;

    if (bookId == 0) {
      _error("Barcode tidak valid");
      return;
    }

    setState(() => processing = true);

    controller.stop();

    try {

      final res = await http.post(
        Uri.parse(ApiConfig.scanBorrow),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": bookId,
        }),
      );

      final data =
          res.body.isNotEmpty
              ? jsonDecode(res.body)
              : {};

      if (!mounted) return;

      if (res.statusCode == 200 &&
          data["success"] == true) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BorrowSuccessPage(
              nama: (data["nama"] ?? "-").toString(),
              judulBuku:
                  (data["judul"] ?? "-").toString(),
              tanggalKembali:
                  (data["tanggal_kembali"] ?? "-")
                      .toString(),
            ),
          ),
        );

        return;
      }

      _error(
        (data["message"] ?? "Gagal scan")
            .toString(),
      );

    } catch (e) {

      _error("Gagal terhubung ke server");
    }

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    setState(() => processing = false);

    controller.start();
  }

  void _error(String msg) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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
                borderRadius:
                    BorderRadius.circular(28),
                border: Border.all(
                  color: KColors.gold,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        KColors.gold.withOpacity(0.4),
                    blurRadius: 22,
                  ),
                ],
              ),
            ),

            AnimatedBuilder(
              animation: lineController,
              builder: (_, __) {

                return Positioned(
                  top: 15 +
                      (220 *
                          lineController.value),
                  left: 18,
                  right: 18,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: KGradient.gold,
                      borderRadius:
                          BorderRadius.circular(20),
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
        padding: const EdgeInsets.fromLTRB(
          20,
          60,
          20,
          30,
        ),
        decoration: const BoxDecoration(
          gradient: KGradient.main,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(36),
          ),
        ),
        child: Column(
          children: [

            const Icon(
              Icons.qr_code_scanner_rounded,
              color: KColors.gold,
              size: 60,
            ),

            const SizedBox(height: 14),

            const Text(
              "Scan Peminjaman Buku",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Arahkan barcode buku ke area scan",
              style: TextStyle(
                color: KColors.softText,
                fontSize: 14,
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

          Positioned(
            bottom: 110,
            left: 25,
            right: 25,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color:
                      KColors.gold.withOpacity(0.35),
                ),
              ),
              child: const Column(
                children: [

                  Text(
                    "Tips Scan",
                    style: TextStyle(
                      color: KColors.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "• Pastikan barcode terlihat jelas\n• Jangan terlalu dekat\n• Gunakan pencahayaan cukup",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
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