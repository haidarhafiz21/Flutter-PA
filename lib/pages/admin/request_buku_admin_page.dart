import 'package:flutter/material.dart';

import '../../services/request_book_service.dart';
import '../../widgets/kejaksaan_ui.dart';

class RequestBukuAdminPage extends StatefulWidget {
  final int adminId;

  const RequestBukuAdminPage({
    super.key,
    required this.adminId,
  });

  @override
  State<RequestBukuAdminPage> createState() => _RequestBukuAdminPageState();
}

class _RequestBukuAdminPageState extends State<RequestBukuAdminPage> {
  List data = [];
  bool loading = true;
  bool processing = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final result = await RequestBookService.getAdminRequests();

    if (!mounted) return;

    setState(() {
      data = result;
      loading = false;
    });
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

  Future<void> prosesRequest(Map item, bool approve) async {
    final catatanController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: KColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: KColors.gold),
          ),
          title: Text(
            approve ? "Setujui Request" : "Tolak Request",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: catatanController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: approve
                  ? "Catatan admin (opsional)"
                  : "Alasan ditolak",
              hintStyle: const TextStyle(color: KColors.softText),
              filled: true,
              fillColor: KColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: KColors.gold.withOpacity(0.35),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: approve ? KColors.gold : KColors.danger,
                foregroundColor: approve ? KColors.dark : Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(approve ? "Setujui" : "Tolak"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => processing = true);

    final id = int.tryParse("${item["id"]}") ?? 0;

    final result = approve
        ? await RequestBookService.approveRequest(
            requestId: id,
            adminId: widget.adminId,
            catatanAdmin: catatanController.text.trim(),
          )
        : await RequestBookService.rejectRequest(
            requestId: id,
            adminId: widget.adminId,
            catatanAdmin: catatanController.text.trim(),
          );

    if (!mounted) return;

    setState(() => processing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"] ?? "Request diproses"),
      ),
    );

    await loadData();
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pengusul: ${item["nama_lengkap"] ?? "-"}",
            style: const TextStyle(color: KColors.gold),
          ),
          Text(
            "Email: ${item["email"] ?? "-"}",
            style: const TextStyle(color: KColors.softText),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 14),
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
            ],
          ),
          if (status == "menunggu") ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: processing
                        ? null
                        : () => prosesRequest(item, false),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text(
                      "Tolak",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KColors.danger,
                      side: const BorderSide(color: KColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: processing
                        ? null
                        : () => prosesRequest(item, true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      "Setujui",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KColors.gold,
                      foregroundColor: KColors.dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
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
      body: Stack(
        children: [
          Column(
            children: [
              KHeader(
                title: "Request Buku",
                subtitle: "Persetujuan usulan buku dari peminjam",
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
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
          if (processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: KColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}
