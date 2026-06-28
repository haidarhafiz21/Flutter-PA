import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../services/borrow_service.dart';
import '../../widgets/kejaksaan_ui.dart';

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
        return KColors.gold;
      case 'dibatalkan':
        return Colors.grey;
      default:
        return KColors.softText;
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

    if (channel.isNotEmpty && channelLower != 'null') return channel;
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

    if (imageUrl.isEmpty) return coverPlaceholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        imageUrl,
        width: 88,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => coverPlaceholder(),
      ),
    );
  }

  Widget coverPlaceholder() {
    return Container(
      width: 88,
      height: 120,
      decoration: BoxDecoration(
        color: KColors.card2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KColors.gold.withOpacity(0.5)),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: KColors.gold,
        size: 42,
      ),
    );
  }

  Widget statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor(status).withOpacity(0.17),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor(status).withOpacity(0.35)),
      ),
      child: Text(
        status,
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
        "$label: ${formatRupiah(value)}",
        style: const TextStyle(
          color: KColors.danger,
          fontWeight: FontWeight.w800,
          fontSize: 13,
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

    return KCard(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      padding: const EdgeInsets.all(14),
      radius: 26,
      borderGold: true,
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
                  "Pinjam: ${formatTanggal(item['tanggal_pinjam'])}",
                  style: KText.body.copyWith(fontSize: 13),
                ),
                Text(
                  status.toLowerCase() == 'dibatalkan'
                      ? "Dibatalkan: ${formatTanggal(item['batas_ambil'])}"
                      : "Dikembalikan: ${formatTanggal(tanggalKembaliTampil)}",
                  style: KText.body.copyWith(fontSize: 13),
                ),
                if (totalDenda > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: KColors.gold.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: KColors.gold.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_rounded,
                          color: KColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Metode Pembayaran: $metodePembayaran",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                dendaText("Denda Terlambat", dendaTerlambat),
                dendaText("Denda Kerusakan", dendaKerusakan),
                dendaText("Denda Kehilangan", dendaKehilangan),
                if (totalDenda > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Total Denda: ${formatRupiah(totalDenda)}",
                    style: const TextStyle(
                      color: KColors.danger,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
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
            Icon(Icons.history_rounded, color: KColors.gold, size: 88),
            SizedBox(height: 16),
            Text(
              "Belum Ada Riwayat",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Riwayat peminjaman akan muncul setelah buku dikembalikan atau dibatalkan.",
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
            title: "Riwayat Peminjaman",
            subtitle: "Catatan pengembalian dan pembayaran",
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
                          itemBuilder: (context, i) {
                            final item = Map<String, dynamic>.from(data[i]);
                            return buildItem(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}