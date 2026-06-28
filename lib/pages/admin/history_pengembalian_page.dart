import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../widgets/kejaksaan_ui.dart';

class HistoryPengembalianPage extends StatefulWidget {
  const HistoryPengembalianPage({super.key});

  @override
  State<HistoryPengembalianPage> createState() =>
      _HistoryPengembalianPageState();
}

class _HistoryPengembalianPageState
    extends State<HistoryPengembalianPage> {
  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/borrows/history-pengembalian"),
      );

      final json = res.body.isNotEmpty ? jsonDecode(res.body) : [];

      if (!mounted) return;

      setState(() {
        data = json is List ? json : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        data = [];
        loading = false;
      });
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";

    try {
      return DateFormat("dd MMM yyyy")
          .format(DateTime.parse(date).toLocal());
    } catch (e) {
      return "-";
    }
  }

  Widget buildCover(String? coverPath) {
    final imageUrl = ApiConfig.fileUrl(coverPath);

    return Container(
      width: 82,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KColors.gold.withOpacity(0.35),
        ),
        image: imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl.isEmpty
          ? const Icon(Icons.book, color: Colors.white)
          : null,
    );
  }

  Widget buildItem(Map<String, dynamic> d) {
    final tanggalKembali =
        d["tanggal_dikembalikan"]?.toString() ??
        d["tanggal_kembali"]?.toString();

    return KCard(
      borderGold: true,
      radius: 28,
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCover(d["cover_buku"]?.toString()),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d["judul"] ?? "-",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: KColors.greenSoft,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Dikembalikan",
                    style: TextStyle(
                      color: KColors.green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  "Peminjam: ${d["nama_lengkap"] ?? "-"}",
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Tanggal Pinjam: ${formatDate(d["tanggal_pinjam"]?.toString())}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Tanggal Kembali: ${formatDate(tanggalKembali)}",
                  style: const TextStyle(
                    color: KColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
      backgroundColor: KColors.bg,
      body: Column(
        children: [
          const KHeader(
            title: "History Pengembalian",
            subtitle: "Riwayat buku yang sudah dikembalikan",
          ),

          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : data.isEmpty
                    ? const Center(
                        child: Text(
                          "Belum ada history pengembalian",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(18),
                          itemCount: data.length,
                          itemBuilder: (context, i) {
                            return buildItem(
                              Map<String, dynamic>.from(data[i]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}