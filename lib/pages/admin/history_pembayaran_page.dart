import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../config/api_config.dart';

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
    final channel = (d["payment_channel"] ?? d["channel"] ?? "").toString().trim();
    final metode = (d["metode"] ?? "").toString().trim();

    if (paymentType.isNotEmpty) {
      if (paymentType.toLowerCase() == "qris") return "QRIS";
      if (paymentType.toLowerCase() == "bank_transfer") {
        return channel.isNotEmpty ? "Transfer Bank - $channel" : "Transfer Bank";
      }
      if (paymentType.toLowerCase() == "echannel") return "Mandiri Bill";
      if (paymentType.toLowerCase() == "gopay") return "GoPay";
      if (paymentType.toLowerCase() == "shopeepay") return "ShopeePay";
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
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "gagal":
      case "expire":
      case "cancel":
        return Colors.red;
      default:
        return Colors.grey;
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

  Widget buildHistoryCard(Map<String, dynamic> d) {
    final status = (d["status"] ?? "-").toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: buildCover(d["cover_buku"]?.toString()),
          title: Text(
            d["nama_lengkap"] ?? "-",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Buku: ${d["judul"] ?? "-"}"),
                Text("Jumlah: ${formatRupiah(d["jumlah"])}"),
                Text("Metode Pembayaran: ${formatMetode(d)}"),
                Text("Tanggal: ${formatDate(d["tanggal"]?.toString())}"),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Status: $status",
                    style: TextStyle(
                      color: statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f3f7),
      appBar: AppBar(
        title: const Text("History Pembayaran Denda"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("Belum ada history pembayaran denda"))
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final d = Map<String, dynamic>.from(data[i]);
                      return buildHistoryCard(d);
                    },
                  ),
                ),
    );
  }
}