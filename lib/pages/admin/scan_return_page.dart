import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'verifikasi_pembayaran_page.dart';

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

class _ScanReturnPageState extends State<ScanReturnPage> {
  bool processing = false;

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  String normalizeCode(String value) {
    return value.trim();
  }

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (processing) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final scannedCode = normalizeCode(rawValue);
    final expectedCode = normalizeCode(widget.barcode);

    if (scannedCode.isEmpty) {
      showMsg("Barcode tidak valid");
      return;
    }

    if (expectedCode.isNotEmpty && scannedCode != expectedCode) {
      showMsg("Barcode buku tidak sesuai dengan data peminjam");
      return;
    }

    setState(() => processing = true);
    controller.stop();

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.returnBook),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "book_id": scannedCode,
          "peminjaman_id": widget.peminjamanId,
          "denda_kerusakan": 0,
          "denda_kehilangan": 0,
        }),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (!mounted) return;

      if (data["butuh_pembayaran"] == true) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifikasiPembayaranPage(
              autoOpenPeminjamanId: data["peminjaman_id"],
            ),
          ),
        );

        if (!mounted) return;

        if (result == true) {
          showMsg("Pembayaran selesai. Data sudah masuk history.");
          Navigator.pop(context, true);
          return;
        } else {
          showMsg(
            data["message"] ??
                "Buku sudah diterima, menunggu pembayaran denda",
          );
        }
      } else if (data["success"] == true) {
        showMsg(data["message"] ?? "Buku berhasil dikembalikan");
        Navigator.pop(context, true);
        return;
      } else {
        showMsg(data["message"] ?? "Pengembalian gagal");
      }
    } catch (e) {
      if (!mounted) return;
      showMsg("Gagal koneksi");
    }

    if (!mounted) return;
    setState(() => processing = false);
    controller.start();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                child: Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Buku: ${widget.judul}"),
                    Text("ID Peminjaman: ${widget.peminjamanId}"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "Barcode / ID Buku: ${widget.barcode}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Pengembalian"),
      ),
      body: Column(
        children: [
          buildInfoCard(),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}