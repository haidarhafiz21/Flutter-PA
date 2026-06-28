import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../services/borrow_service.dart';
import '../../widgets/kejaksaan_ui.dart';
import 'scan_return_page.dart';

class BorrowListPage extends StatefulWidget {
  final String type;

  const BorrowListPage({
    super.key,
    required this.type,
  });

  @override
  State<BorrowListPage> createState() => _BorrowListPageState();
}

class _BorrowListPageState extends State<BorrowListPage> {
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

  String get title {
    if (widget.type == "late") return "Peminjaman Terlambat";
    if (widget.type == "booking") return "Daftar Booking";
    return "Peminjaman Aktif";
  }

  String get subtitle {
    if (widget.type == "late") return "Daftar buku yang melewati batas kembali";
    if (widget.type == "booking") return "Daftar buku yang menunggu diambil";
    return "Daftar buku yang sedang dipinjam";
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      List<dynamic> result = [];

      if (widget.type == "active") {
        result = await BorrowService.getReturnList();
      } else if (widget.type == "late") {
        result = await BorrowService.getLateList();
      } else if (widget.type == "booking") {
        result = await BorrowService.getBookingList();
      } else {
        result = await BorrowService.getReturnList();
      }

      if (!mounted) return;

      setState(() {
        data = result;
        filteredData = result;
        loading = false;
      });

      applySearch();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        data = [];
        filteredData = [];
        loading = false;
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

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";

    try {
      final dt = DateTime.parse(date).toLocal();
      return DateFormat("dd MMM yyyy, HH:mm").format(dt);
    } catch (e) {
      return "-";
    }
  }

  int getDenda(Map<String, dynamic> d) {
    final total = int.tryParse((d['total_denda'] ?? '').toString());
    if (total != null) return total;

    return int.tryParse((d['denda'] ?? '').toString()) ?? 0;
  }

  String formatRupiah(int value) {
    return "Rp ${value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}";
  }

  Color statusColor(String status) {
    switch (status) {
      case "dipinjam":
        return KColors.gold;
      case "terlambat":
        return KColors.danger;
      case "booking":
        return Colors.orange;
      case "menunggu_pembayaran":
        return Colors.deepOrangeAccent;
      default:
        return KColors.softText;
    }
  }

  String statusLabel(String status) {
    switch (status) {
      case "dipinjam":
        return "Sedang Dipinjam";
      case "terlambat":
        return "Terlambat";
      case "booking":
        return "Booking";
      case "menunggu_pembayaran":
        return "Menunggu Pembayaran";
      default:
        return status;
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
        Icons.menu_book_rounded,
        color: KColors.gold,
        size: 42,
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
        statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: KCard(
        borderGold: true,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Cari nama, judul, barcode, status...",
            hintStyle: TextStyle(color: KColors.softText),
            prefixIcon: Icon(Icons.search_rounded, color: KColors.gold),
          ),
        ),
      ),
    );
  }

  Widget buildItem(Map<String, dynamic> d) {
    final status = (d["status"] ?? "-").toString();
    final denda = getDenda(d);

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
                const SizedBox(height: 5),
                Text(
                  "Barcode: ${d["barcode"] ?? "-"}",
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Pinjam: ${formatDate(d["tanggal_pinjam"]?.toString())}",
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Kembali: ${formatDate(d["tanggal_kembali"]?.toString())}",
                  style: const TextStyle(
                    color: KColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (denda > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Denda: ${formatRupiah(denda)}",
                    style: const TextStyle(
                      color: KColors.danger,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (widget.type == "active" || widget.type == "late") ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: KButton(
                      text: "Scan Pengembalian",
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScanReturnPage(
                              peminjamanId: d["id"] ?? 0,
                              userId: d["user_id"] ?? 0,
                              nama: (d["nama_lengkap"] ?? "-").toString(),
                              judul: (d["judul"] ?? "-").toString(),
                              barcode: (d["barcode"] ?? "-").toString(),
                            ),
                          ),
                        ).then((value) {
                          if (value == true) {
                            loadData();
                          }
                        });
                      },
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
        padding: EdgeInsets.all(28),
        child: Text(
          "Tidak ada data peminjaman",
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
            title: title,
            subtitle: subtitle,
            trailing: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          buildSearch(),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: KColors.gold),
                  )
                : filteredData.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            return buildItem(
                              Map<String, dynamic>.from(filteredData[index]),
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