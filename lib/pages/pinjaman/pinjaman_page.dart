import 'package:flutter/material.dart';
import '../../services/borrow_service.dart';

class PinjamanPage extends StatefulWidget {
  final int userId;

  const PinjamanPage({super.key, required this.userId});

  @override
  State<PinjamanPage> createState() => _PinjamanPageState();
}

class _PinjamanPageState extends State<PinjamanPage> {
  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final result = await BorrowService.getUserBorrows(widget.userId);

    if (!mounted) return;

    setState(() {
      data = result.where((e) => e['status'] != 'dikembalikan').toList();
      loading = false;
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case 'booking':
        return Colors.orange;
      case 'dipinjam':
        return Colors.green;
      case 'terlambat':
        return Colors.red;
      case 'menunggu_pembayaran':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String formatTanggal(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    if (text.isEmpty) return "-";

    try {
      final date = DateTime.parse(text).toLocal();
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return text;
    }
  }

  int hitungTerlambatHari(Map item) {
    final tanggalKembaliText = item['tanggal_kembali']?.toString();

    if (tanggalKembaliText == null || tanggalKembaliText.isEmpty) {
      return 0;
    }

    try {
      final tanggalKembali = DateTime.parse(tanggalKembaliText).toLocal();

      DateTime pembanding = DateTime.now();

      final tanggalDikembalikanText =
          item['tanggal_dikembalikan']?.toString();

      if (tanggalDikembalikanText != null &&
          tanggalDikembalikanText.isNotEmpty) {
        pembanding = DateTime.parse(tanggalDikembalikanText).toLocal();
      }

      if (!pembanding.isAfter(tanggalKembali)) return 0;

      final selisihJam = pembanding.difference(tanggalKembali).inHours;
      final hari = (selisihJam / 24).ceil();

      return hari <= 0 ? 1 : hari;
    } catch (e) {
      return 0;
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

  int totalDenda(Map item) {
    return int.tryParse(
          (item['total_denda'] ?? item['denda'] ?? 0).toString(),
        ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinjaman Aktif')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("Tidak ada pinjaman"))
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final item = Map<String, dynamic>.from(data[i]);
                      final status = (item['status'] ?? '-').toString();
                      final terlambatHari = hitungTerlambatHari(item);
                      final denda = totalDenda(item);

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(item['judul'] ?? "-"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Status: $status"),
                              Text(
                                  "Pinjam: ${formatTanggal(item['tanggal_pinjam'])}"),
                              Text(
                                  "Kembali: ${formatTanggal(item['tanggal_kembali'])}"),
                              if (status == 'booking')
                                Text(
                                  "Batas Ambil: ${formatTanggal(item['batas_ambil'])}",
                                  style: const TextStyle(color: Colors.orange),
                                ),
                              if (status == 'terlambat' ||
                                  status == 'menunggu_pembayaran')
                                Text(
                                  "Terlambat: $terlambatHari hari",
                                  style: const TextStyle(color: Colors.red),
                                ),
                              if (denda > 0)
                                Text(
                                  "Total Denda: ${formatRupiah(denda)}",
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (status == 'menunggu_pembayaran')
                                const Text(
                                  "Buku sudah dikembalikan, menunggu pembayaran denda",
                                  style: TextStyle(color: Colors.deepOrange),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: statusColor(status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}