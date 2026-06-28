import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../widgets/kejaksaan_ui.dart';
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
    return "Rp ${number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}";
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
        return KColors.gold;
      case "terlambat":
        return KColors.danger;
      case "menunggu_pembayaran":
        return Colors.deepOrangeAccent;
      default:
        return Colors.grey;
    }
  }

  String statusText(String status) {
    switch (status) {
      case "booking":
        return "Menunggu Diambil";
      case "dipinjam":
        return "Sedang Dipinjam";
      case "terlambat":
        return "Terlambat";
      case "menunggu_pembayaran":
        return "Menunggu Pembayaran";
      default:
        return status;
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

  Widget buildCover(String? coverPath) {
    final imageUrl = ApiConfig.fileUrl(coverPath);

    if (imageUrl.isEmpty) return coverPlaceholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        imageUrl,
        width: 92,
        height: 128,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => coverPlaceholder(),
      ),
    );
  }

  Widget coverPlaceholder() {
    return Container(
      width: 92,
      height: 128,
      decoration: BoxDecoration(
        color: KColors.card2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KColors.gold.withOpacity(0.5)),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: KColors.gold,
        size: 46,
      ),
    );
  }

  Widget statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor(status).withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor(status).withOpacity(0.35)),
      ),
      child: Text(
        statusText(status),
        style: TextStyle(
          color: statusColor(status),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget dendaText(String label, int value) {
    if (value <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        "$label : ${rupiah(value)}",
        style: const TextStyle(
          color: KColors.danger,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
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

    final paymentUrl = (item["payment_url"] ?? "").toString().trim();

    final canPayOnline =
        (status == "terlambat" || status == "menunggu_pembayaran") &&
            paymentUrl.isNotEmpty &&
            !statusBayar;

    return KCard(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      padding: const EdgeInsets.all(14),
      radius: 26,
      borderGold: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCover(item["cover_buku"]?.toString()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["judul"] ?? "-",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                statusBadge(status),
                const SizedBox(height: 10),
                Text(
                  "Pinjam : ${formatDateOnly(item["tanggal_pinjam"]?.toString())}",
                  style: KText.body.copyWith(fontSize: 13),
                ),
                Text(
                  "Kembali : ${formatDateOnly(item["tanggal_kembali"]?.toString())}",
                  style: KText.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                if (status == "booking")
                  Text(
                    "Sisa waktu ambil : ${hitungSisaWaktu(item["batas_ambil"]?.toString())}",
                    style: const TextStyle(
                      color: KColors.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  )
                else
                  Text(
                    "Terlambat : ${hitungTerlambatHari(item["tanggal_kembali"]?.toString(), statusBayar)}",
                    style: TextStyle(
                      color: status == "terlambat"
                          ? KColors.danger
                          : KColors.softText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                if (status == "menunggu_pembayaran") ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.deepOrange.withOpacity(0.35),
                      ),
                    ),
                    child: const Text(
                      "Buku sudah dikembalikan, selesaikan pembayaran denda terlebih dahulu.",
                      style: TextStyle(
                        color: Colors.deepOrangeAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                dendaText("Denda Terlambat", dendaTerlambat),
                dendaText("Denda Kerusakan", dendaKerusakan),
                dendaText("Denda Kehilangan", dendaKehilangan),
                if (totalDenda > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Total Denda : ${rupiah(totalDenda)}",
                    style: const TextStyle(
                      color: KColors.danger,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
                if (canPayOnline) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: KButton(
                      text: "Bayar Online",
                      icon: Icons.payments_rounded,
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentWebviewPage(url: paymentUrl),
                          ),
                        ).then((_) => syncStatus(item["id"] ?? 0));
                      },
                    ),
                  ),
                ] else if ((status == "terlambat" ||
                        status == "menunggu_pembayaran") &&
                    !statusBayar) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Menunggu admin membuat tagihan atau konfirmasi pembayaran.",
                    style: TextStyle(
                      color: KColors.softText,
                      fontSize: 12.5,
                      height: 1.35,
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

  Widget emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_rounded,
              color: KColors.gold,
              size: 88,
            ),
            SizedBox(height: 16),
            Text(
              "Belum Ada Peminjaman",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Buku yang sedang dipinjam akan muncul di halaman ini.",
              textAlign: TextAlign.center,
              style: TextStyle(color: KColors.softText),
            ),
          ],
        ),
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
            title: "Status Peminjaman",
            subtitle: "Pantau buku yang sedang dipinjam",
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            return buildItem(data[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}