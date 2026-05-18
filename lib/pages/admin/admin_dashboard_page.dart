import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'borrow_list_page.dart';
import 'history_pembayaran_page.dart';
import 'history_pengembalian_page.dart';
import 'select_member_page.dart';
import 'verifikasi_pembayaran_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final String nama;
  final int userId;
  final String fotoWajah;

  const AdminDashboardPage({
    super.key,
    required this.nama,
    required this.userId,
    required this.fotoWajah,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

Uint8List? decodeImage(String base64String) {
  try {
    if (base64String.isEmpty) return null;
    if (base64String.contains(',')) {
      base64String = base64String.split(',').last;
    }
    return base64Decode(base64String);
  } catch (_) {
    return null;
  }
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int aktif = 0;
  int terlambat = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/borrows/stats"),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (!mounted) return;

      setState(() {
        aktif = int.tryParse((data["aktif"] ?? 0).toString()) ?? 0;
        terlambat = int.tryParse((data["terlambat"] ?? 0).toString()) ?? 0;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        aktif = 0;
        terlambat = 0;
        loading = false;
      });
    }
  }

  void bukaPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => loadStats());
  }

  Widget statCard({
    required String title,
    required int value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    final bytes = decodeImage(widget.fotoWajah);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 26),
      decoration: const BoxDecoration(
        color: Color(0xff2f6360),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            backgroundImage: bytes != null ? MemoryImage(bytes) : null,
            child: bytes == null
                ? Text(
                    widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : "A",
                    style: const TextStyle(fontSize: 24),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Admin Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.nama,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f5f7),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: loadStats,
                child: ListView(
                  children: [
                    buildHeader(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        statCard(
                          title: "Peminjaman Aktif",
                          value: aktif,
                          color: Colors.orange,
                          onTap: () => bukaPage(
                            const BorrowListPage(type: "active"),
                          ),
                        ),
                        statCard(
                          title: "Peminjaman Terlambat",
                          value: terlambat,
                          color: Colors.deepOrange,
                          onTap: () => bukaPage(
                            const BorrowListPage(type: "late"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    menuTile(
                      icon: Icons.qr_code_scanner,
                      title: "Scan Peminjaman Buku",
                      onTap: () => bukaPage(
                        const SelectMemberPage(type: "borrow"),
                      ),
                    ),
                    menuTile(
                      icon: Icons.assignment_return,
                      title: "Scan Pengembalian Buku",
                      onTap: () => bukaPage(
                        const BorrowListPage(type: "active"),
                      ),
                    ),
                    menuTile(
                      icon: Icons.payments_outlined,
                      title: "Verifikasi Pembayaran",
                      onTap: () => bukaPage(
                        const VerifikasiPembayaranPage(),
                      ),
                    ),
                    menuTile(
                      icon: Icons.receipt_long,
                      title: "History Pembayaran Denda",
                      onTap: () => bukaPage(
                        const HistoryPembayaranPage(),
                      ),
                    ),
                    menuTile(
                      icon: Icons.history,
                      title: "History Pengembalian Buku",
                      onTap: () => bukaPage(
                        const HistoryPengembalianPage(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}