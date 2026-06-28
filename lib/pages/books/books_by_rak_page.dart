import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/book_service.dart';
import '../../widgets/kejaksaan_ui.dart';
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
  List allBooks = [];
  List filteredBooks = [];
  bool loading = true;

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
      final List data;
      if (BookService.isDigitalRack(widget.rak)) {
        data = await BookService.getDigitalBooks();
      } else {
        data = await BookService.getBooksByRack(widget.rak, widget.role);
      }
      if (!mounted) return;
      setState(() {
        allBooks = data;
        filteredBooks = data;
        loading = false;
      });
      filterBooks();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        allBooks = [];
        filteredBooks = [];
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil data buku")),
      );
    }
  }

  List<String> getTahunList() {
    final tahunSet = <String>{};
    for (final item in allBooks) {
      final book = Map<String, dynamic>.from(item);
      final tahun = (book['tahun_terbit'] ?? '').toString();
      if (tahun.isNotEmpty && tahun != 'null') {
        tahunSet.add(tahun);
      }
    }
    final tahunList = tahunSet.toList();
    tahunList.sort((a, b) => b.compareTo(a)); // terbaru -> terlama
    return ["Semua", ...tahunList];
  }

  void filterBooks() {
    final keyword = searchController.text.trim().toLowerCase();
    if (!mounted) return;
    setState(() {
      filteredBooks = allBooks.where((item) {
        final book = Map<String, dynamic>.from(item);
        final judul = (book['judul'] ?? '').toString().toLowerCase();
        final penulis = (book['penulis'] ?? '').toString().toLowerCase();
        final penerbit = (book['penerbit'] ?? '').toString().toLowerCase();
        final kategori = (book['nama_rak'] ?? '').toString().toLowerCase();
        final tahun = (book['tahun_terbit'] ?? '').toString();

        final cocokKeyword = keyword.isEmpty ||
            judul.contains(keyword) ||
            penulis.contains(keyword) ||
            penerbit.contains(keyword) ||
            kategori.contains(keyword) ||
            tahun.contains(keyword);

        final cocokTahun =
            selectedTahun == "Semua" || tahun == selectedTahun;

        return cocokKeyword && cocokTahun;
      }).toList();
    });
  }

  int getStok(Map book) {
    return int.tryParse((book['stok'] ?? 0).toString()) ?? 0;
  }

  bool isDigitalBook(Map book) {
    return book['is_digital'] == true ||
        book['is_digital'].toString().toLowerCase() == 'true' ||
        (book['file_pdf'] ?? '').toString().trim().isNotEmpty;
  }

  // ====================== UI ======================

  Widget buildSearchAndYearFilter() {
    final tahunList = getTahunList();
    final safeSelected =
        tahunList.contains(selectedTahun) ? selectedTahun : "Semua";

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Column(
        children: [
          // ---- Pencarian ----
          KCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            radius: 20,
            borderGold: true,
            child: TextField(
              controller: searchController,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Cari judul, penulis, atau tahun...",
                hintStyle: const TextStyle(color: KColors.softText),
                prefixIcon: const Icon(Icons.search, color: KColors.gold),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: KColors.gold),
                        onPressed: () => searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ---- Filter Tahun ----
          KCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            radius: 18,
            borderGold: true,
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: KColors.gold),
                const SizedBox(width: 10),
                const Text(
                  "Tahun",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: safeSelected,
                      dropdownColor: KColors.card,
                      iconEnabledColor: KColors.gold,
                      isExpanded: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildList() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (filteredBooks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: Text(
            "Buku tidak ditemukan",
            style: TextStyle(color: KColors.softText),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
          child: Text(
            "${filteredBooks.length} buku",
            style: const TextStyle(
              color: KColors.gold,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
        ...filteredBooks.map(
          (item) => bookCard(Map<String, dynamic>.from(item)),
        ),
      ],
    );
  }

  Widget bookCard(Map<String, dynamic> book) {
    final int stok = getStok(book);
    final bool digital = isDigitalBook(book);
    final coverUrl = ApiConfig.fileUrl(book['cover_buku']?.toString());

    return KCard(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      padding: const EdgeInsets.all(12),
      radius: 22,
      borderGold: true,
      child: InkWell(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(),
                    )
                  : _coverPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (book['judul'] ?? '-').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (book['penulis'] ?? '-').toString(),
                    style: const TextStyle(
                      color: KColors.softText,
                      fontSize: 12.5,
                    ),
                  ),
                  if ((book['tahun_terbit'] ?? '').toString().isNotEmpty &&
                      (book['tahun_terbit'] ?? '').toString() != 'null') ...[
                    const SizedBox(height: 3),
                    Text(
                      "Tahun: ${book['tahun_terbit']}",
                      style: const TextStyle(
                        color: KColors.softText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (digital
                              ? KColors.gold
                              : (stok <= 0 ? KColors.danger : KColors.gold))
                          .withOpacity(0.17),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      digital
                          ? "Baca Online"
                          : (stok <= 0 ? "Stok Habis" : "Stok: $stok"),
                      style: TextStyle(
                        color: digital
                            ? KColors.gold
                            : (stok <= 0 ? KColors.danger : KColors.gold),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 70,
      height: 100,
      decoration: BoxDecoration(
        color: KColors.card2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.menu_book_rounded,
          color: KColors.gold, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.bg,
      appBar: AppBar(
        backgroundColor: KColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: KColors.gold),
        title: Text(
          widget.rak,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadBooks,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            buildSearchAndYearFilter(),
            buildList(),
          ],
        ),
      ),
    );
  }
}