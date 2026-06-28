import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../services/borrow_service.dart';
import '../../widgets/kejaksaan_ui.dart';

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
  bool autoOpened = false;

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

    try {
      final result = await BorrowService.getActiveList();

      if (!mounted) return;

      setState(() {
        data = result;
        filteredData = result;
        loading = false;
      });

      applySearch();
      autoOpenIfNeeded();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        data = [];
        filteredData = [];
        loading = false;
      });
    }
  }

  void autoOpenIfNeeded() {
    if (autoOpened || widget.autoOpenPeminjamanId == null) return;

    final found = data.where((item) {
      final d = Map<String, dynamic>.from(item);
      final id = int.tryParse("${d['id']}") ?? 0;
      return id == widget.autoOpenPeminjamanId;
    }).toList();

    if (found.isNotEmpty) {
      autoOpened = true;
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        openDetail(Map<String, dynamic>.from(found.first));
      });
    }
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
        return KColors.gold;
      case 'terlambat':
        return KColors.danger;
      case 'menunggu_pembayaran':
        return Colors.orange;
      default:
        return KColors.softText;
    }
  }

  Color getStatusBgColor(String status) {
    return getStatusColor(status).withOpacity(0.16);
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
        return status.isEmpty ? "-" : status;
    }
  }

  String getCoverPath(Map<String, dynamic> d) {
    return (d['cover_buku'] ??
            d['cover'] ??
            d['gambar'] ??
            d['sampul'] ??
            '')
        .toString();
  }

  Widget buildCover(String? coverPath, Color color) {
    final imageUrl = ApiConfig.fileUrl(coverPath);

    Widget fallback() {
      return Container(
        width: 78,
        height: 105,
        decoration: BoxDecoration(
          color: KColors.card2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KColors.gold.withOpacity(0.45)),
        ),
        child: const Icon(
          Icons.menu_book_rounded,
          color: KColors.gold,
          size: 34,
        ),
      );
    }

    if (imageUrl.isEmpty) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: 78,
        height: 105,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
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
        content: Text(
          result["message"]?.toString() ?? "Denda berhasil disimpan",
        ),
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
        content: Text(
          result["message"]?.toString() ?? "Pembayaran selesai",
        ),
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
                color: KColors.bg,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
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
                            color: KColors.gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Buku: $judul",
                        style: const TextStyle(
                          fontSize: 15,
                          color: KColors.softText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusBgColor(status),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: getStatusColor(status).withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          getStatusText(status),
                          style: TextStyle(
                            color: getStatusColor(status),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: KGradient.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: KColors.gold.withOpacity(0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Denda saat ini",
                              style: TextStyle(
                                color: KColors.softText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(totalTersimpan),
                              style: const TextStyle(
                                color: KColors.danger,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Preview total setelah input: ${formatRupiah(previewTotal)}",
                              style: const TextStyle(
                                color: KColors.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: kerusakanController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Denda Kerusakan",
                          labelStyle: const TextStyle(color: KColors.softText),
                          hintText: "Masukkan nominal kerusakan",
                          hintStyle: const TextStyle(color: KColors.softText),
                          prefixIcon: const Icon(
                            Icons.build_outlined,
                            color: KColors.gold,
                          ),
                          filled: true,
                          fillColor: KColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: KColors.gold.withOpacity(0.45),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: KColors.gold),
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: kehilanganController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Denda Kehilangan",
                          labelStyle: const TextStyle(color: KColors.softText),
                          hintText: "Masukkan nominal kehilangan",
                          hintStyle: const TextStyle(color: KColors.softText),
                          prefixIcon: const Icon(
                            Icons.warning_amber_rounded,
                            color: KColors.gold,
                          ),
                          filled: true,
                          fillColor: KColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: KColors.gold.withOpacity(0.45),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: KColors.gold),
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KColors.gold,
                            foregroundColor: KColors.dark,
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
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: KColors.dark,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: const Text(
                            "Simpan Denda",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (totalAktif <= 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: KColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: KColors.gold.withOpacity(0.35),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: KColors.gold,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Isi nominal denda kerusakan atau kehilangan terlebih dahulu, lalu tekan Simpan Denda agar tombol pembayaran aktif.",
                                  style: TextStyle(
                                    color: KColors.softText,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KColors.gold,
                              side: const BorderSide(color: KColors.gold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => bayarCash(
                              peminjamanId: peminjamanId,
                              jumlah: totalAktif,
                            ),
                            icon: const Icon(Icons.payments_rounded),
                            label: const Text(
                              "Bayar Cash",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => buatTagihanOnline(
                              peminjamanId: peminjamanId,
                            ),
                            icon: const Icon(Icons.qr_code_rounded),
                            label: const Text(
                              "Buat Tagihan Online",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Cari nama / judul / barcode...",
          hintStyle: const TextStyle(color: KColors.softText),
          prefixIcon: const Icon(
            Icons.search,
            size: 26,
            color: KColors.gold,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          filled: true,
          fillColor: KColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: KColors.gold.withOpacity(0.45),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: KColors.gold),
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
      borderRadius: BorderRadius.circular(26),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: KGradient.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: KColors.gold.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCover(getCoverPath(d), color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (d['nama_lengkap'] ?? "-").toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Buku: ${d['judul'] ?? "-"}",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KColors.softText,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Barcode: ${d['barcode'] ?? "-"}",
                    style: const TextStyle(
                      color: KColors.gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
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
                      border: Border.all(color: color.withOpacity(0.35)),
                    ),
                    child: Text(
                      getStatusText(status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Pinjam: ${formatDate(d['tanggal_pinjam']?.toString())}",
                    style: const TextStyle(
                      color: KColors.softText,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    "Kembali: ${formatDate(d['tanggal_kembali']?.toString())}",
                    style: const TextStyle(
                      color: KColors.softText,
                      fontSize: 12.5,
                    ),
                  ),
                  if (denda > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "Denda: ${formatRupiah(denda)}",
                        style: const TextStyle(
                          color: KColors.danger,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 35),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 30,
                color: KColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 140),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 70,
            color: KColors.gold,
          ),
          SizedBox(height: 12),
          Text(
            "Tidak ada data",
            style: TextStyle(
              fontSize: 16,
              color: KColors.softText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: KColors.gold),
      );
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
      backgroundColor: KColors.bg,
      body: Column(
        children: [
          KHeader(
            title: "Verifikasi Pembayaran",
            subtitle: "Validasi denda, cash, dan tagihan online",
            trailing: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(child: buildBody()),
        ],
      ),
    );
  }
}