import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../services/borrow_service.dart';

class VerifikasiPembayaranPage extends StatefulWidget {
  final int? autoOpenPeminjamanId;

  const VerifikasiPembayaranPage({
    super.key,
    this.autoOpenPeminjamanId,
  });

  @override
  State<VerifikasiPembayaranPage> createState() =>
      _VerifikasiPembayaranPageState();
}

class _VerifikasiPembayaranPageState extends State<VerifikasiPembayaranPage> {
  List<dynamic> data = [];
  List<dynamic> filteredData = [];
  bool loading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
    searchController.addListener(applySearch);
  }

  @override
  void dispose() {
    searchController.removeListener(applySearch);
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final result = await BorrowService.getActiveList();

    if (!mounted) return;

    setState(() {
      data = result;
      filteredData = result;
      loading = false;
    });

    applySearch();
  }

  void applySearch() {
    final keyword = searchController.text.trim().toLowerCase();

    if (!mounted) return;

    if (keyword.isEmpty) {
      setState(() {
        filteredData = List<dynamic>.from(data);
      });
      return;
    }

    setState(() {
      filteredData = data.where((item) {
        final d = Map<String, dynamic>.from(item);

        final nama = (d['nama_lengkap'] ?? '').toString().toLowerCase();
        final judul = (d['judul'] ?? '').toString().toLowerCase();
        final barcode = (d['barcode'] ?? '').toString().toLowerCase();
        final status = (d['status'] ?? '').toString().toLowerCase();

        return nama.contains(keyword) ||
            judul.contains(keyword) ||
            barcode.contains(keyword) ||
            status.contains(keyword);
      }).toList();
    });
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) return "-";

    try {
      final dt = DateTime.parse(value).toLocal();
      return DateFormat("dd MMM yyyy, HH:mm").format(dt);
    } catch (_) {
      return "-";
    }
  }

  int getDenda(Map<String, dynamic> d) {
    final total = int.tryParse((d['total_denda'] ?? '').toString());
    if (total != null) return total;

    final denda = int.tryParse((d['denda'] ?? '').toString());
    if (denda != null) return denda;

    return 0;
  }

  int parseNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String formatRupiah(int value) {
    return "Rp ${value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}";
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'dipinjam':
        return Colors.green;
      case 'terlambat':
        return Colors.red;
      case 'menunggu_pembayaran':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color getStatusBgColor(String status) {
    switch (status) {
      case 'dipinjam':
        return Colors.green.withOpacity(0.12);
      case 'terlambat':
        return Colors.red.withOpacity(0.12);
      case 'menunggu_pembayaran':
        return Colors.orange.withOpacity(0.12);
      default:
        return Colors.grey.withOpacity(0.12);
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'dipinjam':
        return "Sedang Dipinjam";
      case 'terlambat':
        return "Terlambat";
      case 'menunggu_pembayaran':
        return "Menunggu Pembayaran";
      default:
        return status;
    }
  }

  Widget buildCover(String? coverPath, Color color) {
    final imageUrl = ApiConfig.fileUrl(coverPath);

    if (imageUrl.isEmpty) {
      return Container(
        width: 74,
        height: 96,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.book, color: Colors.white, size: 32),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: 74,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 74,
            height: 96,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.book, color: Colors.white, size: 32),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> simpanDendaManual({
    required int peminjamanId,
    required int dendaKerusakan,
    required int dendaKehilangan,
  }) async {
    final result = await BorrowService.inputManualDenda(
      peminjamanId: peminjamanId,
      dendaKerusakan: dendaKerusakan,
      dendaKehilangan: dendaKehilangan,
    );

    if (!mounted) return result;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"]?.toString() ?? "Denda berhasil disimpan"),
      ),
    );

    return Map<String, dynamic>.from(result);
  }

  Future<void> bayarCash({
    required int peminjamanId,
    required int jumlah,
  }) async {
    final result = await BorrowService.bayarOffline(
      peminjamanId: peminjamanId,
      jumlah: jumlah,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"]?.toString() ?? "Pembayaran selesai"),
      ),
    );

    Navigator.pop(context);
    await loadData();
  }

  Future<void> buatTagihanOnline({
    required int peminjamanId,
  }) async {
    final result = await BorrowService.bayarOnline(
      peminjamanId: peminjamanId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"]?.toString() ?? "Tagihan dibuat"),
      ),
    );

    Navigator.pop(context);
    await loadData();
  }

  Future<void> openDetail(Map<String, dynamic> d) async {
    final peminjamanId = int.tryParse("${d['id']}") ?? 0;
    String status = (d['status'] ?? '').toString();

    final nama = (d['nama_lengkap'] ?? '-').toString();
    final judul = (d['judul'] ?? '-').toString();

    int dendaTerlambatAwal =
        int.tryParse("${d['denda_terlambat'] ?? 0}") ?? 0;

    int totalTersimpan = getDenda(d);

    final kerusakanAwal = int.tryParse("${d['denda_kerusakan'] ?? 0}") ?? 0;
    final kehilanganAwal = int.tryParse("${d['denda_kehilangan'] ?? 0}") ?? 0;

    final kerusakanController = TextEditingController(
      text: kerusakanAwal > 0 ? kerusakanAwal.toString() : "",
    );

    final kehilanganController = TextEditingController(
      text: kehilanganAwal > 0 ? kehilanganAwal.toString() : "",
    );

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final dendaKerusakan = parseNumber(kerusakanController.text);
            final dendaKehilangan = parseNumber(kehilanganController.text);

            final previewTotal =
                dendaTerlambatAwal + dendaKerusakan + dendaKehilangan;

            final totalAktif = previewTotal > 0 ? previewTotal : totalTersimpan;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Buku: $judul",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusBgColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getStatusText(status),
                          style: TextStyle(
                            color: getStatusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Denda saat ini",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(totalTersimpan),
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Preview total setelah input: ${formatRupiah(previewTotal)}",
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextField(
                        controller: kerusakanController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Denda Kerusakan",
                          hintText: "Masukkan nominal kerusakan",
                          prefixIcon: const Icon(Icons.build_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: kehilanganController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Denda Kehilangan",
                          hintText: "Masukkan nominal kehilangan",
                          prefixIcon: const Icon(Icons.warning_amber_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: saving
                              ? null
                              : () async {
                                  setModalState(() => saving = true);

                                  final result = await simpanDendaManual(
                                    peminjamanId: peminjamanId,
                                    dendaKerusakan: dendaKerusakan,
                                    dendaKehilangan: dendaKehilangan,
                                  );

                                  final row = Map<String, dynamic>.from(
                                    result["data"] ?? {},
                                  );

                                  totalTersimpan = int.tryParse(
                                        "${row["total_denda"] ?? previewTotal}",
                                      ) ??
                                      previewTotal;

                                  dendaTerlambatAwal = int.tryParse(
                                        "${row["denda_terlambat"] ?? dendaTerlambatAwal}",
                                      ) ??
                                      dendaTerlambatAwal;

                                  status = "menunggu_pembayaran";

                                  setModalState(() => saving = false);
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Simpan Denda",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: totalAktif > 0
                              ? () => bayarCash(
                                    peminjamanId: peminjamanId,
                                    jumlah: totalAktif,
                                  )
                              : null,
                          child: const Text(
                            "Bayar Cash",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepOrange,
                            side: const BorderSide(color: Colors.deepOrange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: totalAktif > 0
                              ? () => buatTagihanOnline(
                                    peminjamanId: peminjamanId,
                                  )
                              : null,
                          child: const Text(
                            "Buat Tagihan Online",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await loadData();
  }

  Widget buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Cari nama / judul / barcode...",
          prefixIcon: const Icon(Icons.search, size: 26),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.green),
          ),
        ),
      ),
    );
  }

  Widget buildItem(Map<String, dynamic> d) {
    final status = (d['status'] ?? '').toString();
    final color = getStatusColor(status);
    final denda = getDenda(d);

    return InkWell(
      onTap: () => openDetail(d),
      borderRadius: BorderRadius.circular(22),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildCover(d['cover_buku']?.toString(), color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (d['nama_lengkap'] ?? "-").toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Buku: ${d['judul'] ?? "-"}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Barcode: ${d['barcode'] ?? "-"}",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusBgColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        getStatusText(status),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pinjam: ${formatDate(d['tanggal_pinjam']?.toString())}",
                    ),
                    Text(
                      "Kembali: ${formatDate(d['tanggal_kembali']?.toString())}",
                    ),
                    if (denda > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "Denda: ${formatRupiah(denda)}",
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Icon(Icons.chevron_right, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 140),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            "Tidak ada data",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          buildSearchBox(),
          if (filteredData.isEmpty)
            buildEmptyState()
          else
            ...filteredData.map((item) {
              final d = Map<String, dynamic>.from(item);
              return buildItem(d);
            }),
          const SizedBox(height: 22),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f9),
      appBar: AppBar(
        backgroundColor: const Color(0xfff7f7f9),
        elevation: 0,
        title: const Text(
          "Verifikasi Pembayaran",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: buildBody(),
    );
  }
}