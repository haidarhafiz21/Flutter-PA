import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/borrow_service.dart';
import '../../config/api_config.dart';

class RiwayatPage extends StatefulWidget {
  final int userId;

  const RiwayatPage({super.key, required this.userId});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final result = await BorrowService.getUserBorrows(widget.userId);

      if (!mounted) return;

      final filtered = result.where((e) {
        if (e is! Map) return false;

        final status = (e['status'] ?? '').toString().toLowerCase();

        return status == 'dikembalikan' || status == 'dibatalkan';
      }).toList();

      setState(() {
        data = filtered;
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
    switch (status.toLowerCase()) {
      case 'dikembalikan':
        return Colors.blue;
      case 'dibatalkan':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  String formatRupiah(dynamic value) {
    final int number = int.tryParse((value ?? 0).toString()) ?? 0;

    return "Rp ${number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}";
  }

  String formatTanggal(dynamic value) {
    if (value == null) return "-";

    final text = value.toString().trim();
    if (text.isEmpty) return "-";

    try {
      final dt = DateTime.parse(text).toLocal();
      return DateFormat("dd MMM yyyy").format(dt);
    } catch (e) {
      return text;
    }
  }

  String formatMetodePembayaran(Map<String, dynamic> item) {
    final metode = (item['metode_pembayaran'] ?? '').toString().trim();
    final paymentType = (item['payment_type'] ?? '').toString().trim();
    final channel = (item['payment_channel'] ?? '').toString().trim();

    final metodeLower = metode.toLowerCase();
    final paymentTypeLower = paymentType.toLowerCase();
    final channelLower = channel.toLowerCase();

    if (channel.isNotEmpty && channelLower != 'null') {
      return channel;
    }

    if (metodeLower == 'cash') return 'Cash';

    if (paymentTypeLower == 'echannel') return 'Mandiri Bill';
    if (paymentTypeLower == 'qris') return 'QRIS';
    if (paymentTypeLower == 'bank_transfer') return 'Bank Transfer';
    if (paymentTypeLower == 'credit_card') return 'Credit Card';
    if (paymentTypeLower == 'gopay') return 'GoPay';
    if (paymentTypeLower == 'shopeepay') return 'ShopeePay';
    if (paymentTypeLower == 'cstore') return 'Convenience Store';

    if (metodeLower == 'online') return 'Online / Midtrans';

    if (metode.isNotEmpty && metodeLower != 'null') return metode;

    return '-';
  }

  Widget buildCover(String? coverPath) {
    final imageUrl = ApiConfig.fileUrl(coverPath);

    if (imageUrl.isEmpty) {
      return Container(
        width: 62,
        height: 84,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.book, size: 28),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 62,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 62,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.book, size: 28),
          );
        },
      ),
    );
  }

  Widget buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildItem(Map<String, dynamic> item) {
    final status = (item['status'] ?? '-').toString();

    final denda = int.tryParse((item['denda'] ?? 0).toString()) ?? 0;
    final dendaTerlambat =
        int.tryParse((item['denda_terlambat'] ?? 0).toString()) ?? 0;
    final dendaKerusakan =
        int.tryParse((item['denda_kerusakan'] ?? 0).toString()) ?? 0;
    final dendaKehilangan =
        int.tryParse((item['denda_kehilangan'] ?? 0).toString()) ?? 0;
    final totalDenda =
        int.tryParse((item['total_denda'] ?? denda).toString()) ?? denda;

    final tanggalKembaliTampil =
        item['tanggal_dikembalikan'] ?? item['tanggal_kembali'];

    final metodePembayaran = formatMetodePembayaran(item);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCover(item['cover_buku']?.toString()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['judul'] ?? "-",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildStatusBadge(status),
                  const SizedBox(height: 10),
                  Text(
                    "Pinjam: ${formatTanggal(item['tanggal_pinjam'])}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    status.toLowerCase() == 'dibatalkan'
                        ? "Dibatalkan: ${formatTanggal(item['batas_ambil'])}"
                        : "Dikembalikan: ${formatTanggal(tanggalKembaliTampil)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (totalDenda > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Metode Pembayaran: $metodePembayaran",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (dendaTerlambat > 0)
                    Text(
                      "Denda Terlambat: ${formatRupiah(dendaTerlambat)}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (dendaKerusakan > 0)
                    Text(
                      "Denda Kerusakan: ${formatRupiah(dendaKerusakan)}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (dendaKehilangan > 0)
                    Text(
                      "Denda Kehilangan: ${formatRupiah(dendaKehilangan)}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (totalDenda > 0)
                    Text(
                      "Total Denda: ${formatRupiah(totalDenda)}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f2f5),
      appBar: AppBar(
        title: const Text('Riwayat Peminjaman'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("Belum ada riwayat"))
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final item = Map<String, dynamic>.from(data[i]);
                      return buildItem(item);
                    },
                  ),
                ),
    );
  }
}