import 'package:flutter/material.dart';

import '../../services/request_book_service.dart';
import '../../widgets/kejaksaan_ui.dart';

class RiwayatRequestBukuPage extends StatefulWidget {
  final int userId;

  const RiwayatRequestBukuPage({
    super.key,
    required this.userId,
  });

  @override
  State<RiwayatRequestBukuPage> createState() =>
      _RiwayatRequestBukuPageState();
}

class _RiwayatRequestBukuPageState extends State<RiwayatRequestBukuPage> {
  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final result = await RequestBookService.getUserRequests(widget.userId);

    if (!mounted) return;

    setState(() {
      data = result;
      loading = false;
    });
  }

  String formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return "-";

    try {
      final dt = DateTime.parse(raw).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return "-";
    }
  }

  Color statusColor(String status) {
    if (status == "disetujui") return KColors.gold;
    if (status == "ditolak") return KColors.danger;
    return Colors.orange;
  }

  String statusText(String status) {
    if (status == "disetujui") return "Disetujui";
    if (status == "ditolak") return "Ditolak";
    return "Menunggu";
  }

  Widget itemCard(Map item) {
    final status = (item["status"] ?? "menunggu").toString();
    final color = statusColor(status);

    return KCard(
      borderGold: status == "menunggu",
      radius: 26,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item["judul_buku"] ?? "-",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Penulis: ${item["penulis"] ?? "-"}",
            style: const TextStyle(color: KColors.softText),
          ),
          Text(
            "Penerbit: ${item["penerbit"] ?? "-"}",
            style: const TextStyle(color: KColors.softText),
          ),
          Text(
            "Tahun: ${item["tahun_terbit"] ?? "-"}",
            style: const TextStyle(color: KColors.softText),
          ),
          Text(
            "Rak: ${item["kategori_rak"] ?? "-"}",
            style: const TextStyle(color: KColors.gold),
          ),
          const SizedBox(height: 10),
          Text(
            "Alasan: ${item["alasan"] ?? "-"}",
            style: const TextStyle(
              color: KColors.softText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  statusText(status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatDate(item["created_at"]?.toString()),
                style: const TextStyle(
                  color: KColors.softText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if ((item["catatan_admin"] ?? "").toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              "Catatan Admin: ${item["catatan_admin"]}",
              style: const TextStyle(
                color: KColors.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
          KHeader(
            title: "Riwayat Request",
            subtitle: "Status usulan buku yang pernah dikirim",
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
                    ? const Center(
                        child: Text(
                          "Belum ada request buku",
                          style: TextStyle(color: KColors.softText),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(18),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            return itemCard(
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