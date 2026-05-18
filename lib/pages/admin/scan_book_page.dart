import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'borrow_success_page.dart';

class ScanBookPage extends StatefulWidget {
  final int userId;

  const ScanBookPage({super.key, required this.userId});

  @override
  State<ScanBookPage> createState() => _ScanBookPageState();
}

class _ScanBookPageState extends State<ScanBookPage> {
  bool scanned = false;
  final MobileScannerController controller = MobileScannerController();

  Future<void> processScan(String code) async {
    int bookId = int.tryParse(code) ?? 0;

    if (bookId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Barcode tidak valid")),
      );
      scanned = false;
      controller.start();
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.scanBorrow),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": bookId
        }),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (data["success"] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BorrowSuccessPage(
              nama: data["nama"] ?? "-",
              judulBuku: data["judul"] ?? "-",
              tanggalKembali: data["tanggal_kembali"] ?? "-",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Gagal scan")),
        );

        scanned = false;
        controller.start();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );

      scanned = false;
      controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Buku')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (scanned) return;

          final code = capture.barcodes.first.rawValue;
          if (code == null) return;

          scanned = true;
          controller.stop();
          processScan(code);
        },
      ),
    );
  }
}