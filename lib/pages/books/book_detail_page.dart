import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/borrow_service.dart';
import '../../widgets/kejaksaan_ui.dart';
import '../pickup/pickup_countdown_page.dart';

class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> book;
  final int userId;
  final String role;

  const BookDetailPage({
    super.key,
    required this.book,
    required this.userId,
    required this.role,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  String? localPath;
  bool loading = false;

  // ===== Ketersediaan / jadwal pengembalian =====
  List<Map<String, dynamic>> pinjamanAktif = [];
  bool loadingPinjaman = true;

  bool get isDigital {
    return widget.book['is_digital'] == true ||
        widget.book['is_digital'].toString().toLowerCase() == 'true';
  }

  bool get hasPdf {
    return (widget.book['file_pdf'] ?? '').toString().trim().isNotEmpty;
  }

  bool get isBisaDibaca => (isDigital || hasPdf) && hasPdf;

  int get stok {
    return int.tryParse((widget.book['stok'] ?? 0).toString()) ?? 0;
  }

  bool get stokHabis => stok <= 0;

  @override
  void initState() {
    super.initState();
    if (isDigital) {
      loadingPinjaman = false;
    } else {
      loadKetersediaan();
    }
  }

  // ====================== AMBIL DATA KETERSEDIAAN ======================
  Future<void> loadKetersediaan() async {
    try {
      final semuaAktif = await BorrowService.getActiveList();
      final bukuId = int.tryParse((widget.book['id'] ?? '').toString());

      final List<Map<String, dynamic>> filtered = [];
      for (final item in semuaAktif) {
        final map = Map<String, dynamic>.from(item as Map);
        final bId = int.tryParse((map['buku_id'] ?? '').toString());
        if (bukuId != null && bId == bukuId) {
          filtered.add(map);
        }
      }

      if (!mounted) return;
      setState(() {
        pinjamanAktif = filtered;
        loadingPinjaman = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        pinjamanAktif = [];
        loadingPinjaman = false;
      });
    }
  }

  DateTime? parseTanggal(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty || s == 'null') return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String formatTanggal(DateTime? dt) {
    if (dt == null) return "-";
    const bulan = [
      "",
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember"
    ];
    return "${dt.day} ${bulan[dt.month]} ${dt.year}";
  }

  Future<void> downloadPDF() async {
    setState(() => loading = true);
    try {
      final url = "${ApiConfig.readBook}/${widget.book['id']}";
      print("DEBUG_PDF_URL: $url");
      final response = await http.get(Uri.parse(url));
      print("DEBUG_PDF_STATUS: ${response.statusCode}");
      print("DEBUG_PDF_TYPE: ${response.headers['content-type']}");
      print("DEBUG_PDF_LEN: ${response.bodyBytes.length}");

      if (response.statusCode != 200 || !isPdfResponse(response)) {
        throw Exception(
            "Status ${response.statusCode}, type ${response.headers['content-type']}");
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/book_${widget.book['id']}.pdf");
      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (!mounted) return;
      setState(() {
        localPath = file.path;
        loading = false;
      });
    } catch (e) {
      print("DEBUG_PDF_ERROR: $e");
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e")),
      );
    }
  }

  bool isPdfResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? "";
    final bytes = response.bodyBytes;
    return contentType.toLowerCase().contains("application/pdf") ||
        (bytes.length >= 4 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46);
  }

  Future<void> pinjamBuku() async {
    if (stokHabis || loading) return;
    setState(() => loading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.booking),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": widget.book['id'],
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (!mounted) return;

      if (data["success"] == true) {
        final batasAmbilString = data["batas_ambil"]?.toString();
        if (batasAmbilString == null || batasAmbilString.isEmpty) {
          setState(() => loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Batas ambil tidak ditemukan")),
          );
          return;
        }
        final batasAmbil = DateTime.parse(batasAmbilString).toLocal();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'borrow_pickup_deadline',
          batasAmbil.millisecondsSinceEpoch,
        );
        if (!mounted) return;
        setState(() => loading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PickupCountdownPage(userId: widget.userId),
          ),
        );
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Booking gagal")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server")),
      );
    }
  }

  Widget buildCover() {
    final imageUrl = ApiConfig.fileUrl(widget.book['cover_buku']?.toString());
    if (imageUrl.isEmpty) {
      return coverPlaceholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.network(
        imageUrl,
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => coverPlaceholder(),
      ),
    );
  }

  Widget coverPlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: KColors.softGreen,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: KColors.green,
          size: 90,
        ),
      ),
    );
  }

  Color stokColor() {
    if (isBisaDibaca) return KColors.gold;
    if (stok == 0) return KColors.danger;
    if (stok <= 2) return Colors.orange;
    return KColors.green;
  }

  Widget infoBadge({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value, IconData icon) {
    return KCard(
      margin: const EdgeInsets.only(bottom: 12),
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: KGradient.gold,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: KColors.dark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================== KOTAK KETERSEDIAAN / JADWAL KEMBALI ======================
  Widget buildKetersediaan() {
    if (isDigital) return const SizedBox.shrink();

    if (loadingPinjaman) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    // hanya eksemplar yang benar-benar masih dipegang peminjam
    final aktif = pinjamanAktif.where((p) {
      final s = (p['status'] ?? '').toString();
      return s == 'dipinjam' || s == 'terlambat';
    }).toList();

    // Tidak ada yang sedang dipinjam
    if (aktif.isEmpty) {
      return KCard(
        margin: const EdgeInsets.only(bottom: 12),
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (stokHabis ? KColors.danger : KColors.green)
                    .withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                stokHabis
                    ? Icons.info_rounded
                    : Icons.check_circle_rounded,
                color: stokHabis ? KColors.danger : KColors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                stokHabis
                    ? "Stok sedang kosong. Belum ada jadwal pengembalian yang tercatat."
                    : "Semua eksemplar tersedia saat ini.",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Kumpulkan tanggal kembali & yang terlambat
    final now = DateTime.now();
    final List<DateTime> tglKembaliList = [];
    final List<Map<String, dynamic>> terlambatList = [];

    for (final p in aktif) {
      final dt = parseTanggal(p['tanggal_kembali']);
      if (dt != null) {
        tglKembaliList.add(dt);
        final s = (p['status'] ?? '').toString();
        if (s == 'terlambat' || dt.isBefore(now)) {
          terlambatList.add(p);
        }
      }
    }
    tglKembaliList.sort();

    // Perkiraan tersedia = jatuh tempo paling awal yang belum lewat
    DateTime? perkiraan;
    for (final dt in tglKembaliList) {
      if (dt.isAfter(now)) {
        perkiraan = dt;
        break;
      }
    }
    perkiraan ??= tglKembaliList.isNotEmpty ? tglKembaliList.first : null;

    DateTime? terlambatTerlama;
    if (terlambatList.isNotEmpty) {
      final tgls = terlambatList
          .map((p) => parseTanggal(p['tanggal_kembali']))
          .whereType<DateTime>()
          .toList()
        ..sort();
      if (tgls.isNotEmpty) terlambatTerlama = tgls.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Kotak TERLAMBAT (muncul walau stok masih ada) ----
        if (terlambatList.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KColors.danger.withOpacity(0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: KColors.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${terlambatList.length} eksemplar sedang terlambat dikembalikan",
                        style: const TextStyle(
                          color: KColors.danger,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Seharusnya kembali ${formatTanggal(terlambatTerlama)}. Ketersediaan buku ini bisa tertunda.",
                        style: const TextStyle(
                          color: KColors.softText,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // ---- Kotak INFO KETERSEDIAAN / PERKIRAAN TERSEDIA ----
        KCard(
          margin: const EdgeInsets.only(bottom: 12),
          radius: 20,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: KGradient.gold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: KColors.dark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stokHabis
                          ? "Stok sedang kosong"
                          : "Tersedia sekarang: $stok eksemplar",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      perkiraan != null
                          ? "${aktif.length} eksemplar sedang dipinjam. Perkiraan tersedia kembali sekitar ${formatTanggal(perkiraan)}."
                          : "${aktif.length} eksemplar sedang dipinjam. Perkiraan tanggal kembali belum tersedia.",
                      style: const TextStyle(
                        color: KColors.softText,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    if (tglKembaliList.length > 1) ...[
                      const SizedBox(height: 8),
                      ...tglKembaliList.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "• Jadwal kembali: ${formatTanggal(d)}",
                            style: const TextStyle(
                              color: KColors.softText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool tombolBaca = isBisaDibaca;
    final bool tombolPinjam = !isDigital && !stokHabis;

    return Scaffold(
      backgroundColor: KColors.bg,
      body: localPath != null
          ? PDFView(filePath: localPath!)
          : Column(
              children: [
                KHeader(
                  title: "Detail Buku",
                  subtitle: "Informasi lengkap koleksi",
                  trailing: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      buildCover(),
                      const SizedBox(height: 20),
                      Text(
                        (widget.book['judul'] ?? "-").toString(),
                        style: const TextStyle(
                          color: KColors.goldLight,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          infoBadge(
                            icon: tombolBaca
                                ? Icons.chrome_reader_mode_rounded
                                : Icons.inventory_2_rounded,
                            title: tombolBaca
                                ? "Baca Online"
                                : stokHabis
                                    ? "Stok Habis"
                                    : "Stok: $stok",
                            color: stokColor(),
                          ),
                          infoBadge(
                            icon: tombolBaca
                                ? Icons.picture_as_pdf_rounded
                                : Icons.local_library_rounded,
                            title:
                                tombolBaca ? "Koleksi PDF" : "Koleksi Fisik",
                            color: tombolBaca ? KColors.gold : KColors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // 🔽 Kotak baru: perkiraan tersedia + status terlambat
                      buildKetersediaan(),
                      const SizedBox(height: 6),
                      infoRow(
                        "Penulis",
                        (widget.book['penulis'] ?? "-").toString(),
                        Icons.person_rounded,
                      ),
                      infoRow(
                        "Penerbit",
                        (widget.book['penerbit'] ?? "-").toString(),
                        Icons.business_rounded,
                      ),
                      infoRow(
                        "Tahun Terbit",
                        (widget.book['tahun_terbit'] ?? "-").toString(),
                        Icons.calendar_month_rounded,
                      ),
                      const SizedBox(height: 8),
                      KCard(
                        radius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Deskripsi Buku",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              (widget.book['deskripsi'] ?? "-").toString(),
                              style: KText.body.copyWith(fontSize: 14.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      KButton(
                        text: loading
                            ? "Memproses..."
                            : tombolBaca
                                ? "Baca PDF"
                                : tombolPinjam
                                    ? "Pinjam Buku"
                                    : isDigital
                                        ? "Hanya Bisa Dibaca"
                                        : "Stok Habis",
                        icon: tombolBaca
                            ? Icons.picture_as_pdf_rounded
                            : Icons.menu_book_rounded,
                        loading: loading,
                        onTap: loading
                            ? null
                            : tombolBaca
                                ? downloadPDF
                                : tombolPinjam
                                    ? pinjamBuku
                                    : null,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}