import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../payment_webview_page.dart';

class BorrowStatusPage extends StatefulWidget {
  final int userId;

  const BorrowStatusPage({super.key, required this.userId});

  @override
  State<BorrowStatusPage> createState() => _BorrowStatusPageState();
}

class _BorrowStatusPageState extends State<BorrowStatusPage> {
  List data = [];
  bool loading = true;
  Timer? timer;
  int refreshTick = 0;

  @override
  void initState() {
    super.initState();
    loadData();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      refreshTick++;

      if (refreshTick % 15 == 0) {
        loadData(showLoading: false);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String rupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;
    final str = number.toString();
    final buffer = StringBuffer();
    int counter = 0;

    for (int i = str.length - 1; i >= 0; i--) {
      counter++;
      buffer.write(str[i]);
      if (counter == 3 && i != 0) {
        buffer.write('.');
        counter = 0;
      }
    }

    return "Rp ${buffer.toString().split('').reversed.join()}";
  }

  String formatDateOnly(String? date) {
    if (date == null || date.isEmpty) return "-";
    try {
      final dt = DateTime.parse(date).toLocal();
      const bulan = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return "${dt.day.toString().padLeft(2, '0')} ${bulan[dt.month]} ${dt.year}";
    } catch (e) {
      return "-";
    }
  }

  String hitungTerlambatHari(String? tanggalKembali, bool statusBayar) {
    if (tanggalKembali == null || tanggalKembali.isEmpty || statusBayar) {
      return "-";
    }

    try {
      final kembali = DateTime.parse(tanggalKembali).toLocal();
      final now = DateTime.now();

      if (now.isBefore(kembali)) return "-";

      final diff = now.difference(kembali);
      final hari = (diff.inHours / 24).ceil();

      return "${hari <= 0 ? 1 : hari} hari";
    } catch (e) {
      return "-";
    }
  }

  String hitungSisaWaktu(String? batasAmbil) {
    if (batasAmbil == null || batasAmbil.isEmpty) return "-";

    try {
      final deadline = DateTime.parse(batasAmbil).toLocal();
      final now = DateTime.now();

      if (now.isAfter(deadline)) return "00:00";

      final diff = deadline.difference(now);
      final menit = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
      final detik = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
      return "$menit:$detik";
    } catch (e) {
      return "-";
    }
  }

  Future<void> loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => loading = true);
    }

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.activeBorrows}?user_id=${widget.userId}"),
      );

      final result = res.body.isNotEmpty ? jsonDecode(res.body) : [];

      if (!mounted) return;

      setState(() {
        data = result is List ? result : [];
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

  Color statusColor(String status) {
    switch (status) {
      case "booking":
        return Colors.orange;
      case "dipinjam":
        return Colors.green;
      case "terlambat":
        return Colors.red;
      case "menunggu_pembayaran":
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Future<void> syncStatus(int peminjamanId) async {
    try {
      await http.get(
        Uri.parse("${ApiConfig.baseUrl}/payment/sync-status/$peminjamanId"),
      );
      await loadData(showLoading: false);
    } catch (_) {}
  }

  Widget buildItem(Map item) {
    final status = (item["status"] ?? "-").toString();
    final statusBayar = item["status_bayar"] == true;

    final dendaTerlambat =
        int.tryParse((item["denda_terlambat"] ?? 0).toString()) ?? 0;
    final dendaKerusakan =
        int.tryParse((item["denda_kerusakan"] ?? 0).toString()) ?? 0;
    final dendaKehilangan =
        int.tryParse((item["denda_kehilangan"] ?? 0).toString()) ?? 0;
    final totalDenda =
        int.tryParse((item["total_denda"] ?? item["denda"] ?? 0).toString()) ??
            0;

    final imageUrl = ApiConfig.fileUrl(item["cover_buku"]?.toString());

    final paymentUrl = (item["payment_url"] ?? "").toString().trim();
    final canPayOnline =
        (status == "terlambat" || status == "menunggu_pembayaran") &&
            paymentUrl.isNotEmpty &&
            !statusBayar;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 82,
                    height: 108,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 82,
                      height: 108,
                      color: Colors.orange,
                      child: const Icon(Icons.book, color: Colors.white),
                    ),
                  )
                : Container(
                    width: 82,
                    height: 108,
                    color: Colors.orange,
                    child: const Icon(Icons.book, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["judul"] ?? "-",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Pinjam : ${formatDateOnly(item["tanggal_pinjam"]?.toString())}",
                ),
                Text(
                  "Pengembalian : ${formatDateOnly(item["tanggal_kembali"]?.toString())}",
                ),
                if (status == "booking") ...[
                  Text(
                    "Sisa waktu: ${hitungSisaWaktu(item["batas_ambil"]?.toString())}",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Text(
                    "Terlambat : ${hitungTerlambatHari(item["tanggal_kembali"]?.toString(), statusBayar)}",
                  ),
                ],
                if (status == "menunggu_pembayaran") ...[
                  const SizedBox(height: 4),
                  const Text(
                    "Buku sudah dikembalikan, tinggal selesaikan pembayaran denda.",
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (dendaTerlambat > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Denda Terlambat : ${rupiah(dendaTerlambat)}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (dendaKerusakan > 0) ...[
                  Text(
                    "Denda Kerusakan : ${rupiah(dendaKerusakan)}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (dendaKehilangan > 0) ...[
                  Text(
                    "Denda Kehilangan : ${rupiah(dendaKehilangan)}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  "Total Denda : ${rupiah(totalDenda)}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (canPayOnline) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentWebviewPage(url: paymentUrl),
                          ),
                        ).then((_) => syncStatus(item["id"] ?? 0));
                      },
                      child: const Text(
                        "Bayar Online",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ] else if ((status == "terlambat" ||
                        status == "menunggu_pembayaran") &&
                    !statusBayar) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Menunggu admin membuat tagihan online atau konfirmasi pembayaran.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
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
      backgroundColor: const Color(0xfff5f2f5),
      appBar: AppBar(
        title: const Text("Status Peminjaman"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("Tidak ada peminjaman"))
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 18),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return buildItem(data[index]);
                    },
                  ),
                ),
    );
  }
}
