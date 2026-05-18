import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../config/api_config.dart';

class HistoryPengembalianPage extends StatefulWidget {
  const HistoryPengembalianPage({super.key});

  @override
  State<HistoryPengembalianPage> createState() =>
      _HistoryPengembalianPageState();
}

class _HistoryPengembalianPageState extends State<HistoryPengembalianPage> {
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
      return DateFormat("dd MMM yyyy").format(DateTime.parse(date).toLocal());
    } catch (e) {
      return "-";
    }
  }

  Widget buildCover(String? coverPath) {
    final imageUrl = ApiConfig.fileUrl(coverPath);

    if (imageUrl.isEmpty) {
      return const CircleAvatar(
        radius: 28,
        child: Icon(Icons.book),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History Pengembalian Buku"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("Belum ada history pengembalian"))
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final d = Map<String, dynamic>.from(data[i]);
                      final tanggalKembali =
                          d["tanggal_dikembalikan"]?.toString() ??
                          d["tanggal_kembali"]?.toString();

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          leading: buildCover(d["cover_buku"]?.toString()),
                          title: Text(d["nama_lengkap"] ?? "-"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Buku: ${d["judul"] ?? "-"}"),
                              Text("Pinjam: ${formatDate(d["tanggal_pinjam"]?.toString())}"),
                              Text("Dikembalikan: ${formatDate(tanggalKembali)}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}