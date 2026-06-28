import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../widgets/kejaksaan_ui.dart';

class HistoryPembayaranPage extends StatefulWidget {
  const HistoryPembayaranPage({super.key});

  @override
  State<HistoryPembayaranPage> createState() => _HistoryPembayaranPageState();
}

class _HistoryPembayaranPageState extends State<HistoryPembayaranPage> {
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
        Uri.parse("${ApiConfig.baseUrl}/borrows/history-pembayaran"),
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

  String formatRupiah(dynamic value) {
    final number = int.tryParse((value ?? 0).toString()) ?? 0;

    final text = number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );

    return "Rp $text";
  }

  String formatMetode(Map<String, dynamic> d) {
    final paymentType = (d["payment_type"] ?? "").toString().trim();
    final channel =
        (d["payment_channel"] ?? d["channel"] ?? "").toString().trim();
    final metode = (d["metode"] ?? d["metode_pembayaran"] ?? "")
        .toString()
        .trim();

    if (paymentType.isNotEmpty) {
      final type = paymentType.toLowerCase();

      if (type == "qris") return "QRIS";
      if (type == "bank_transfer") {
        return channel.isNotEmpty ? "Transfer Bank - $channel" : "Transfer Bank";
      }
      if (type == "echannel") return "Mandiri Bill";
      if (type == "gopay") return "GoPay";
      if (type == "shopeepay") return "ShopeePay";

      return paymentType;
    }

    if (metode.toLowerCase() == "cash") return "Cash / Offline";
    if (metode.toLowerCase() == "online") return "Online / Midtrans";

    return metode.isNotEmpty ? metode : "-";
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "sukses":
      case "settlement":
      case "paid":
      case "berhasil":
        return KColors.gold;
      case "pending":
        return Colors.orange;
      case "gagal":
      case "expire":
      case "cancel":
        return KColors.danger;
      default:
        return KColors.softText;
    }
  }

  Widget buildCover(String? coverPath) {
    final imageUrl = ApiConfig.fileUrl(coverPath);

    if (imageUrl.isEmpty) {
      return coverPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        imageUrl,
        width: 82,
        height: 118,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => coverPlaceholder(),
      ),
    );
  }

  Widget coverPlaceholder() {
    return Container(
      width: 82,
      height: 118,
      decoration: BoxDecoration(
        color: KColors.card2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KColors.gold.withOpacity(0.45)),
      ),
      child: const Icon(
        Icons.receipt_long_rounded,
        color: KColors.gold,
        size: 38,
      ),
    );
  }

  Widget statusBadge(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        status.isEmpty ? "Berhasil" : status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildItem(Map<String, dynamic> d) {
    final status = (d["status_pembayaran"] ??
            d["payment_status"] ??
            d["status"] ??
            "Berhasil")
        .toString();

    final total =
        d["jumlah"] ?? d["total_denda"] ?? d["total"] ?? d["denda"] ?? 0;
    final tanggalBayar =
        (d["tanggal_bayar"] ?? d["tanggal"] ?? d["created_at"])?.toString();

    return KCard(
      borderGold: true,
      radius: 28,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCover(d["cover_buku"]?.toString()),
          const SizedBox(width: 14),
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
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                statusBadge(status),
                const SizedBox(height: 10),
                Text(
                  "Peminjam: ${d["nama_lengkap"] ?? "-"}",
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Metode: ${formatMetode(d)}",
                  style: const TextStyle(
                    color: KColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Tanggal: ${formatDate(tanggalBayar)}",
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Total: ${formatRupiah(total)}",
                  style: const TextStyle(
                    color: KColors.danger,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
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
        padding: EdgeInsets.all(28),
        child: Text(
          "Belum ada history pembayaran denda",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: KColors.softText,
            fontSize: 15,
          ),
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
          KHeader(
            title: "History Pembayaran",
            subtitle: "Riwayat pembayaran denda buku",
            trailing: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: KColors.gold),
                  )
                : data.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            return buildItem(
                              Map<String, dynamic>.from(data[index]),
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
