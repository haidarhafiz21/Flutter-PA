import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/book_service.dart';
import '../books/books_by_rak_page.dart';
import '../pickup/pickup_countdown_page.dart';
import '../../config/api_config.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String role;
  final String nama;
  final String fotoWajah;

  const HomePage({
    super.key,
    required this.userId,
    required this.role,
    required this.nama,
    required this.fotoWajah,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List recommendedBooks = [];
  bool loading = true;
  bool bookingLoading = false;

  Uint8List safeBase64(String data) {
    try {
      if (data.contains(',')) {
        data = data.split(',').last;
      }
      return base64Decode(data);
    } catch (e) {
      return Uint8List(0);
    }
  }

  @override
  void initState() {
    super.initState();
    loadRecommended();
  }

  Future<void> loadRecommended() async {
    try {
      final data = await BookService.getRecommended(widget.role);

      if (!mounted) return;

      setState(() {
        recommendedBooks = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("LOAD RECOMMENDED ERROR: $e");

      if (!mounted) return;

      setState(() {
        recommendedBooks = [];
        loading = false;
      });
    }
  }

  Future<void> pinjamBuku(Map book) async {
    if (bookingLoading) return;

    final stok = int.tryParse((book['stok'] ?? 0).toString()) ?? 0;

    if (stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stok buku habis")),
      );
      return;
    }

    setState(() => bookingLoading = true);

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.booking),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": book['id'],
        }),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      debugPrint("BOOKING RESPONSE: ${res.body}");

      if (!mounted) return;

      if (data["success"] == true) {
        final batasAmbilString = data["batas_ambil"]?.toString();

        if (batasAmbilString == null || batasAmbilString.isEmpty) {
          setState(() => bookingLoading = false);

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

        setState(() => bookingLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PickupCountdownPage(userId: widget.userId),
          ),
        );
      } else {
        setState(() => bookingLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Booking gagal")),
        );
      }
    } catch (e) {
      debugPrint("BOOKING ERROR: $e");

      if (!mounted) return;

      setState(() => bookingLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server")),
      );
    }
  }

  Widget rakItem(String namaRak, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BooksByRakPage(
              rak: namaRak,
              userId: widget.userId,
              role: widget.role,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 3,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                namaRak,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rekomendasiCard(Map book) {
    final String judul = (book['judul'] ?? '-').toString();
    final String penulis = (book['penulis'] ?? "-").toString();
    final String deskripsi = (book['deskripsi'] ?? "-").toString();
    final String imageUrl = ApiConfig.fileUrl(book['cover_buku']?.toString());
    final int totalDipinjam =
        int.tryParse((book['total_dipinjam'] ?? 0).toString()) ?? 0;

    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 12, bottom: 6, top: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 115,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 115,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.book, size: 36),
                      );
                    },
                  )
                : Container(
                    height: 115,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.book, size: 36),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                children: [
                  Text(
                    judul,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    penulis,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deskripsi,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade700,
                      height: 1.2,
                    ),
                  ),
                  if (totalDipinjam > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Dipinjam: $totalDipinjam kali",
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 1,
                        backgroundColor: Colors.deepOrangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: bookingLoading
                          ? null
                          : () {
                              pinjamBuku(book);
                            },
                      child: bookingLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Pinjam",
                              style: TextStyle(fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = safeBase64(widget.fotoWajah);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadRecommended,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          imageBytes.isNotEmpty ? MemoryImage(imageBytes) : null,
                      child:
                          imageBytes.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Selamat Datang\n${widget.nama}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.notifications),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Rekomendasi Buku",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 285,
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : recommendedBooks.isEmpty
                          ? const Center(child: Text("Belum ada rekomendasi"))
                          : ListView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              children: recommendedBooks
                                  .map(
                                    (b) => rekomendasiCard(
                                      Map<String, dynamic>.from(b),
                                    ),
                                  )
                                  .toList(),
                            ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Rak Buku",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.15,
                  children: [
                    rakItem("Hukum Pidana", Icons.gavel),
                    rakItem("Hukum Perdata", Icons.balance),
                    rakItem("Kriminologi", Icons.search),
                    rakItem("Hukum Tata Negara", Icons.account_balance),
                    rakItem("Administrasi", Icons.account_balance),
                    rakItem("Referensi Umum", Icons.book),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}