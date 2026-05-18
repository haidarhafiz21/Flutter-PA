import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../pickup/pickup_countdown_page.dart';

class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> book;
  final int userId;
  final String role;

  const BookDetailPage({
    super.key,
    required this.book,
    required this.userId,
    required this.role,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  String? localPath;
  bool loading = false;

  bool get isDigital {
    return widget.book['is_digital'] == true ||
        widget.book['is_digital'].toString().toLowerCase() == 'true';
  }

  bool get hasPdf {
    return (widget.book['file_pdf'] ?? '').toString().trim().isNotEmpty;
  }

  bool get isBisaDibaca => false;

  int get stok {
    return int.tryParse((widget.book['stok'] ?? 0).toString()) ?? 0;
  }

  bool get stokHabis => stok <= 0;

  Future<void> downloadPDF() async {
    setState(() => loading = true);

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.readBook}/${widget.book['id']}"),
      );

      if (response.statusCode != 200) {
        throw Exception("Gagal download PDF");
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/book_${widget.book['id']}.pdf");

      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (!mounted) return;

      setState(() {
        localPath = file.path;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka PDF")),
      );
    }
  }

  Future<void> pinjamBuku() async {
    if (stokHabis || loading) return;

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.booking),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": widget.book['id'],
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      debugPrint("BOOKING RESPONSE: ${response.body}");

      if (!mounted) return;

      if (data["success"] == true) {
        final batasAmbilString = data["batas_ambil"]?.toString();

        if (batasAmbilString == null || batasAmbilString.isEmpty) {
          setState(() => loading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Batas ambil tidak ditemukan")),
          );
          return;
        }

        final batasAmbil = DateTime.parse(batasAmbilString).toLocal();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'borrow_pickup_deadline',
          batasAmbil.millisecondsSinceEpoch,
        );

        if (!mounted) return;

        setState(() => loading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PickupCountdownPage(userId: widget.userId),
          ),
        );
      } else {
        setState(() => loading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Booking gagal")),
        );
      }
    } catch (e) {
      debugPrint("BOOKING ERROR: $e");

      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server")),
      );
    }
  }

  Widget buildCover() {
    final imageUrl = ApiConfig.fileUrl(widget.book['cover_buku']?.toString());

    if (imageUrl.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade300,
        ),
        child: const Center(
          child: Icon(Icons.book, size: 80),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade300,
            ),
            child: const Center(
              child: Icon(Icons.book, size: 80),
            ),
          );
        },
      ),
    );
  }

  Color stokColor() {
    if (stok == 0) return Colors.red;
    if (stok <= 2) return Colors.orange;
    return Colors.green;
  }

  Widget stokInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: stokColor().withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Stok tersedia: $stok",
        style: TextStyle(
          color: stokColor(),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool tombolBaca = isBisaDibaca;
    final bool tombolPinjam = !stokHabis;

    return Scaffold(
      appBar: AppBar(
        title: Text((widget.book['judul'] ?? "-").toString()),
      ),
      body: localPath != null
          ? PDFView(filePath: localPath!)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                buildCover(),
                const SizedBox(height: 20),
                Text(
                  (widget.book['judul'] ?? "-").toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Penulis: ${(widget.book['penulis'] ?? "-").toString()}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 14),
                stokInfo(),
                const SizedBox(height: 20),
                Text(
                  (widget.book['deskripsi'] ?? "-").toString(),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : tombolBaca
                            ? () {
                                downloadPDF();
                              }
                            : tombolPinjam
                                ? () {
                                    pinjamBuku();
                                  }
                                : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tombolBaca
                          ? Colors.green
                          : tombolPinjam
                              ? Colors.deepOrangeAccent
                              : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            tombolBaca
                                ? "Baca PDF"
                                : tombolPinjam
                                    ? "Pinjam"
                                    : "Stok Habis",
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}