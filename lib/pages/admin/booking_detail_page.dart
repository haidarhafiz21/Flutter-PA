import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/borrow_service.dart';
import '../../config/api_config.dart';

class BookingDetailPage extends StatefulWidget {
  final int userId;

  const BookingDetailPage({super.key, required this.userId});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  Map<String, dynamic>? booking;
  bool loading = true;

  Timer? timer;
  Duration remaining = Duration.zero;

  bool scanLoading = false;
  final MobileScannerController scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    loadBooking();
  }

  @override
  void dispose() {
    timer?.cancel();
    scannerController.dispose();
    super.dispose();
  }

  Future<void> loadBooking() async {
    setState(() => loading = true);

    final data = await BorrowService.getUserBooking(widget.userId);

    if (!mounted) return;

    if (data is List && data.isNotEmpty) {
      booking = Map<String, dynamic>.from(data[0]);
      final batas = DateTime.parse(booking!["batas_ambil"]).toLocal();
      startCountdown(batas);
    } else {
      booking = null;
      timer?.cancel();
      remaining = Duration.zero;
    }

    setState(() => loading = false);
  }

  void startCountdown(DateTime batas) {
    timer?.cancel();

    timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;

      final now = DateTime.now();
      final diff = batas.difference(now);

      if (diff.isNegative) {
        timer?.cancel();
        setState(() => remaining = Duration.zero);
      } else {
        setState(() => remaining = diff);
      }
    });
  }

  String formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return "${two(minutes)}:${two(seconds)}";
  }

  Widget buildCover(String? coverPath) {
    final imageUrl = ApiConfig.fileUrl(coverPath);

    if (imageUrl.isEmpty) {
      return Container(
        width: 110,
        height: 150,
        color: Colors.grey.shade300,
        child: const Icon(Icons.book, size: 40),
      );
    }

    return Image.network(
      imageUrl,
      width: 110,
      height: 150,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 110,
          height: 150,
          color: Colors.grey.shade300,
          child: const Icon(Icons.book, size: 40),
        );
      },
    );
  }

  Future<void> scanBorrow(String barcode) async {
    if (scanLoading) return;

    setState(() => scanLoading = true);

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/borrows/scan"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": barcode,
        }),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (!mounted) return;

      setState(() => scanLoading = false);

      if (data["success"] == true) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Scan peminjaman berhasil")),
        );

        await loadBooking();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Scan peminjaman gagal")),
        );

        scannerController.start();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => scanLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server")),
      );

      scannerController.start();
    }
  }

  void openScanner() {
    scanLoading = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Scan Barcode Buku"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () {
                    scannerController.toggleTorch();
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                MobileScanner(
                  controller: scannerController,
                  onDetect: (capture) async {
                    if (scanLoading) return;

                    final barcodes = capture.barcodes;
                    if (barcodes.isEmpty) return;

                    final code = barcodes.first.rawValue;
                    if (code == null || code.trim().isEmpty) return;

                    await scannerController.stop();
                    await scanBorrow(code.trim());
                  },
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 4),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 40,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      scanLoading
                          ? "Memproses barcode..."
                          : "Arahkan kamera ke barcode buku",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = booking?["cover_buku"]?.toString();

    return Scaffold(
      appBar: AppBar(title: const Text("Booking User")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : booking == null
              ? const Center(child: Text("Tidak ada booking aktif"))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "BARCODE: ${booking!["barcode"] ?? booking!["buku_id"]}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: buildCover(cover),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            booking!["judul"] ?? "-",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            booking!["penulis"] ?? "-",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: remaining == Duration.zero
                                ? const Text(
                                    "Waktu habis",
                                    key: ValueKey("expired"),
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  )
                                : Text(
                                    "Sisa waktu: ${formatTime(remaining)}",
                                    key: const ValueKey("running"),
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 25),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text("Scan Buku"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: remaining == Duration.zero
                                ? null
                                : () {
                                    openScanner();
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}