import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
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

  String get pageTitle {
    return widget.type == "borrow"
        ? "Pilih Anggota Booking"
        : "Pilih Peminjam Aktif";
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
      );
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
      return CircleAvatar(
        radius: 26,
        backgroundColor: Colors.green.shade100,
        child: const Icon(Icons.book),
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.green.shade100,
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, __) {},
    );
  }

  Widget buildMemberCard(Map member) {
    final status = (member["status"] ?? "-").toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: buildCover(member["cover_buku"]?.toString()),
        title: Text(member["nama_lengkap"] ?? "-"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Buku: ${member["judul"] ?? "-"}"),
            Text("ID Buku / Barcode: ${member["barcode"] ?? "-"}"),
            if (widget.type != "borrow") Text("Status: $status"),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => pilihMember(member),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : filteredMembers.isEmpty
              ? Center(child: Text(emptyText))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: searchController,
                        onChanged: searchMember,
                        decoration: InputDecoration(
                          hintText: "Cari nama / judul / barcode...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: loadMembers,
                        child: ListView.builder(
                          itemCount: filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = filteredMembers[index];
                            return buildMemberCard(member);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}