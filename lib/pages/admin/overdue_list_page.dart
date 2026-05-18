import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class OverdueListPage extends StatefulWidget {
  const OverdueListPage({super.key});

  @override
  State<OverdueListPage> createState() => _OverdueListPageState();
}

class _OverdueListPageState extends State<OverdueListPage> {
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
        Uri.parse("${ApiConfig.baseUrl}/borrows/late-list"),
      );

      setState(() {
        data = jsonDecode(res.body);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  /// 🔥 FORMAT RUPIAH
  String formatRupiah(dynamic value) {
    int val = int.tryParse(value.toString()) ?? 0;

    return "Rp ${val.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}";
  }

  /// 🔥 FORMAT TANGGAL
  String formatTanggal(String? date) {
    if (date == null) return "-";

    final d = DateTime.parse(date);
    return "${d.day.toString().padLeft(2, '0')} "
        "${_bulan(d.month)} ${d.year}";
  }

  String _bulan(int m) {
    const bulan = [
      "", "Jan", "Feb", "Mar", "Apr", "Mei",
      "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
    ];
    return bulan[m];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Peminjaman Terlambat")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("Tidak ada data"))
              : ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (c, i) {
                    final d = data[i];

                    return Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          /// ICON
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.book,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(width: 12),

                          /// TEXT
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['nama_lengkap'] ?? "-",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "Buku: ${d['judul'] ?? '-'}",
                                  style: const TextStyle(fontSize: 14),
                                ),

                                const SizedBox(height: 4),

                                const Text(
                                  "Terlambat",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "Pinjam: ${formatTanggal(d['tanggal_pinjam'])}",
                                ),
                                Text(
                                  "Kembali: ${formatTanggal(d['tanggal_kembali'])}",
                                ),

                                const SizedBox(height: 6),

                                /// 🔥 DENDA WAJIB MUNCUL
                                Text(
                                  "Denda: ${formatRupiah(d['denda'])}",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}