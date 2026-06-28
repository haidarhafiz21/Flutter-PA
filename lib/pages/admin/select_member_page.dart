import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../widgets/kejaksaan_ui.dart';
import 'booking_detail_page.dart';
import 'scan_return_page.dart';

class SelectMemberPage extends StatefulWidget {
  final String type;

  const SelectMemberPage({
    super.key,
    required this.type,
  });

  @override
  State<SelectMemberPage> createState() => _SelectMemberPageState();
}

class _SelectMemberPageState extends State<SelectMemberPage> {
  final TextEditingController searchController = TextEditingController();

  List members = [];
  List filteredMembers = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String get pageTitle {
    return widget.type == "borrow"
        ? "Pilih Anggota Booking"
        : "Pilih Peminjam Aktif";
  }

  String get pageSubtitle {
    return widget.type == "borrow"
        ? "Pilih anggota untuk proses scan peminjaman"
        : "Pilih anggota untuk proses pengembalian";
  }

  String get emptyText {
    return widget.type == "borrow"
        ? "Tidak ada booking aktif"
        : "Tidak ada data peminjaman aktif";
  }

  Future<void> loadMembers() async {
    setState(() => loading = true);

    final String url = widget.type == "borrow"
        ? "${ApiConfig.baseUrl}/borrows/booking-list"
        : "${ApiConfig.baseUrl}/borrows/active-list";

    try {
      final res = await http.get(Uri.parse(url));
      final data = res.body.isNotEmpty ? jsonDecode(res.body) : [];

      if (!mounted) return;

      setState(() {
        members = data is List ? data : [];
        filteredMembers = data is List ? data : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        members = [];
        filteredMembers = [];
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil data")),
      );
    }
  }

  void searchMember(String text) {
    final keyword = text.toLowerCase().trim();

    final results = members.where((m) {
      final nama = (m['nama_lengkap'] ?? "").toString().toLowerCase();
      final judul = (m['judul'] ?? "").toString().toLowerCase();
      final barcode = (m['barcode'] ?? "").toString().toLowerCase();

      return nama.contains(keyword) ||
          judul.contains(keyword) ||
          barcode.contains(keyword);
    }).toList();

    setState(() => filteredMembers = results);
  }

  void pilihMember(Map member) {
    if (widget.type == "borrow") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailPage(
            userId: member["user_id"],
          ),
        ),
      ).then((_) => loadMembers());
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanReturnPage(
          peminjamanId: member["id"] ?? 0,
          userId: member["user_id"] ?? 0,
          nama: (member["nama_lengkap"] ?? "-").toString(),
          judul: (member["judul"] ?? "-").toString(),
          barcode: (member["barcode"] ?? "-").toString(),
        ),
      ),
    ).then((_) => loadMembers());
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
        width: 76,
        height: 106,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => coverPlaceholder(),
      ),
    );
  }

  Widget coverPlaceholder() {
    return Container(
      width: 76,
      height: 106,
      decoration: BoxDecoration(
        color: KColors.card2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KColors.gold.withOpacity(0.45)),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: KColors.gold,
        size: 38,
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
          onChanged: searchMember,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Cari nama, judul, atau barcode...",
            hintStyle: TextStyle(color: KColors.softText),
            prefixIcon: Icon(Icons.search_rounded, color: KColors.gold),
          ),
        ),
      ),
    );
  }

  Widget buildMemberCard(Map member) {
    final status = (member["status"] ?? "-").toString();

    return KCard(
      borderGold: true,
      radius: 26,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      onTap: () => pilihMember(member),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCover(member["cover_buku"]?.toString()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member["nama_lengkap"] ?? "-",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  member["judul"] ?? "-",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Barcode: ${member["barcode"] ?? "-"}",
                  style: const TextStyle(
                    color: KColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                if (widget.type != "borrow") ...[
                  const SizedBox(height: 6),
                  Text(
                    "Status: $status",
                    style: const TextStyle(
                      color: KColors.softText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: KColors.gold,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
          style: const TextStyle(
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
            title: pageTitle,
            subtitle: pageSubtitle,
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
                : filteredMembers.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadMembers,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filteredMembers.length,
                          itemBuilder: (context, index) {
                            return buildMemberCard(
                              Map<String, dynamic>.from(filteredMembers[index]),
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