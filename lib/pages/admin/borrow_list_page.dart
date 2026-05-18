import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../services/borrow_service.dart';
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

  Future<void> loadData() async {
    setState(() {
      loading = true;
    });

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

  Color getStatusColor(String status) {
    switch (status) {
      case 'booking':
        return Colors.blue;
      case 'dipinjam':
        return Colors.green;
      case 'terlambat':
        return Colors.red;
      case 'menunggu_pembayaran':
        return Colors.orange;
      case 'dikembalikan':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'booking':
        return "Booking";
      case 'dipinjam':
        return "Sedang Dipinjam";
      case 'terlambat':
        return "Terlambat";
      case 'menunggu_pembayaran':
        return "Menunggu Pembayaran";
      case 'dikembalikan':
        return "Sudah Dikembalikan";
      default:
        return status.isEmpty ? "-" : status;
    }
  }

  Widget buildCover(String? coverPath, Color color) {
    final imageUrl = ApiConfig.fileUrl(coverPath);

    if (imageUrl.isEmpty) {
      return Container(
        width: 70,
        height: 90,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.book, color: Colors.white),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 70,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 70,
            height: 90,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.book, color: Colors.white),
          );
        },
      ),
    );
  }

  Future<void> openDetail(Map<String, dynamic> d) async {
    if (widget.type != "active") return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanReturnPage(
          peminjamanId: int.tryParse("${d['id']}") ?? 0,
          userId: int.tryParse("${d['user_id']}") ?? 0,
          nama: (d['nama_lengkap'] ?? "-").toString(),
          judul: (d['judul'] ?? "-").toString(),
          barcode: (d['barcode'] ?? "-").toString(),
        ),
      ),
    );

    if (result == true) {
      await loadData();
    }
  }

  String getPageTitle() {
    if (widget.type == "active") return "Pilih Peminjam Aktif";
    if (widget.type == "late") return "Peminjaman Terlambat";
    if (widget.type == "booking") return "Daftar Booking";
    return "Daftar Peminjaman";
  }

  Widget buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Cari nama / judul / barcode...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget buildItem(Map<String, dynamic> d) {
    final status = (d['status'] ?? '').toString();
    final statusColor = getStatusColor(status);
    final denda = getDenda(d);

    return InkWell(
      onTap: () => openDetail(d),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildCover(d['cover_buku']?.toString(), statusColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (d['nama_lengkap'] ?? "-").toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Buku: ${d['judul'] ?? "-"}"),
                    Text("ID Buku / Barcode: ${d['barcode'] ?? "-"}"),
                    const SizedBox(height: 6),
                    Text(
                      "Status: ${getStatusText(status)}",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Pinjam : ${formatDate(d['tanggal_pinjam']?.toString())}"),
                    Text("Kembali : ${formatDate(d['tanggal_kembali']?.toString())}"),
                    if (denda > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "Denda : ${formatRupiah(denda)}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.type == "active")
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Icon(Icons.chevron_right),
                ),
            ],
          ),
        ),
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
            const Padding(
              padding: EdgeInsets.only(top: 140),
              child: Center(
                child: Text("Tidak ada data"),
              ),
            )
          else
            ...filteredData.map((item) {
              final d = Map<String, dynamic>.from(item);
              return buildItem(d);
            }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getPageTitle()),
      ),
      body: buildBody(),
    );
  }
}