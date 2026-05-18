import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../services/book_service.dart';
import '../pickup/pickup_countdown_page.dart';
import 'book_detail_page.dart';

class BooksByRakPage extends StatefulWidget {
  final String rak;
  final int userId;
  final String role;

  const BooksByRakPage({
    super.key,
    required this.rak,
    required this.userId,
    required this.role,
  });

  @override
  State<BooksByRakPage> createState() => _BooksByRakPageState();
}

class _BooksByRakPageState extends State<BooksByRakPage> {
  List books = [];
  List filteredBooks = [];

  bool loading = true;
  bool bookingLoading = false;

  final TextEditingController searchController = TextEditingController();
  String selectedTahun = "Semua";

  @override
  void initState() {
    super.initState();
    loadBooks();
    searchController.addListener(filterBooks);
  }

  @override
  void dispose() {
    searchController.removeListener(filterBooks);
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadBooks() async {
    try {
      final data = await BookService.getBooksByRack(
        widget.rak,
        widget.role,
      );

      if (!mounted) return;

      setState(() {
        books = data;
        filteredBooks = data;
        loading = false;
      });

      filterBooks();
    } catch (e) {
      debugPrint("LOAD BOOKS BY RAK ERROR: $e");

      if (!mounted) return;

      setState(() {
        books = [];
        filteredBooks = [];
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil data buku")),
      );
    }
  }

  void filterBooks() {
    final keyword = searchController.text.trim().toLowerCase();

    if (!mounted) return;

    setState(() {
      filteredBooks = books.where((item) {
        final book = Map<String, dynamic>.from(item);

        final judul = (book['judul'] ?? '').toString().toLowerCase();
        final penulis = (book['penulis'] ?? '').toString().toLowerCase();
        final penerbit = (book['penerbit'] ?? '').toString().toLowerCase();
        final kategori = (book['nama_rak'] ?? widget.rak).toString().toLowerCase();
        final tahun = (book['tahun_terbit'] ?? '').toString();

        final cocokKeyword = keyword.isEmpty ||
            judul.contains(keyword) ||
            penulis.contains(keyword) ||
            penerbit.contains(keyword) ||
            kategori.contains(keyword) ||
            tahun.contains(keyword);

        final cocokTahun = selectedTahun == "Semua" || tahun == selectedTahun;

        return cocokKeyword && cocokTahun;
      }).toList();
    });
  }

  List<String> getTahunList() {
    final tahunSet = <String>{};

    for (final item in books) {
      final book = Map<String, dynamic>.from(item);
      final tahun = (book['tahun_terbit'] ?? '').toString();

      if (tahun.isNotEmpty && tahun != 'null') {
        tahunSet.add(tahun);
      }
    }

    final tahunList = tahunSet.toList();
    tahunList.sort((a, b) => b.compareTo(a));

    return ["Semua", ...tahunList];
  }

  Future<void> pinjamBuku(Map<String, dynamic> book) async {
    if (bookingLoading) return;

    final int stok = getStok(book);
    if (stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stok buku habis")),
      );
      return;
    }

    setState(() => bookingLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.booking),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": book['id'],
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      debugPrint("BOOKING RESPONSE: ${response.body}");

      if (!mounted) return;

      if (data["success"] == true) {
        final batasAmbilString = data["batas_ambil"]?.toString();

        if (batasAmbilString == null || batasAmbilString.isEmpty) {
          setState(() => bookingLoading = false);
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

        setState(() => bookingLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PickupCountdownPage(userId: widget.userId),
          ),
        );
      } else {
        setState(() => bookingLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Booking gagal")),
        );
      }
    } catch (e) {
      debugPrint("BOOKING ERROR: $e");

      if (!mounted) return;

      setState(() => bookingLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server")),
      );
    }
  }

  String getCover(String? cover) {
    return ApiConfig.fileUrl(cover);
  }

  bool isBisaDibaca(Map book) {
    return false;
  }

  int getStok(Map book) {
    return int.tryParse((book['stok'] ?? 0).toString()) ?? 0;
  }

  Widget buildCover(Map book) {
    final coverUrl = getCover(book['cover_buku']?.toString());

    if (coverUrl.isEmpty) {
      return Container(
        width: 70,
        height: 95,
        color: Colors.grey.shade300,
        child: const Icon(Icons.book, size: 40),
      );
    }

    return Image.network(
      coverUrl,
      width: 70,
      height: 95,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 70,
          height: 95,
          color: Colors.grey.shade300,
          child: const Icon(Icons.book, size: 40),
        );
      },
    );
  }

  Color stokColor(int stok) {
    if (stok == 0) return Colors.red;
    if (stok <= 2) return Colors.orange;
    return Colors.green;
  }

  Widget stokBadge(int stok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: stokColor(stok).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "Stok: $stok",
        style: TextStyle(
          color: stokColor(stok),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildSearchAndFilter() {
    final tahunList = getTahunList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Cari judul, penulis, kategori, tahun...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Filter Tahun:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTahun,
                      isExpanded: true,
                      items: tahunList.map((tahun) {
                        return DropdownMenuItem<String>(
                          value: tahun,
                          child: Text(tahun),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedTahun = value);
                        filterBooks();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget bookCard(Map<String, dynamic> book) {
    final bool bisaDibaca = isBisaDibaca(book);
    final int stok = getStok(book);
    final bool stokHabis = stok <= 0;

    final bool tombolBaca = bisaDibaca;
    final bool tombolPinjam = !bisaDibaca && !stokHabis;

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: buildCover(book),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (book['judul'] ?? '-').toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (book['penulis'] ?? '-').toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  if ((book['tahun_terbit'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Tahun: ${book['tahun_terbit']}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  stokBadge(stok),
                  const SizedBox(height: 8),
                  Text(
                    (book['deskripsi'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailPage(
                            book: book,
                            userId: widget.userId,
                            role: widget.role,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Baca selengkapnya",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tombolBaca
                      ? Colors.green
                      : tombolPinjam
                          ? Colors.deepOrangeAccent
                          : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                onPressed: bookingLoading
                    ? null
                    : tombolBaca
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookDetailPage(
                                  book: book,
                                  userId: widget.userId,
                                  role: widget.role,
                                ),
                              ),
                            );
                          }
                        : tombolPinjam
                            ? () {
                                pinjamBuku(book);
                              }
                            : null,
                child: bookingLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        tombolBaca
                            ? "Baca"
                            : tombolPinjam
                                ? "Pinjam"
                                : "Habis",
                        style: const TextStyle(fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getPageTitle() {
    if (widget.rak.toLowerCase() == "b") {
      return "Koleksi";
    }
    return widget.rak;
  }

  Widget buildEmptySearch() {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Text("Buku tidak ditemukan"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getPageTitle()),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
              ? const Center(child: Text("Tidak ada buku di rak ini"))
              : RefreshIndicator(
                  onRefresh: loadBooks,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      buildSearchAndFilter(),
                      const SizedBox(height: 6),
                      if (filteredBooks.isEmpty)
                        buildEmptySearch()
                      else
                        ...filteredBooks.map((item) {
                          return bookCard(Map<String, dynamic>.from(item));
                        }),
                      const SizedBox(height: 16),
                    ],
                  ),
                ), 
    );
  }
}