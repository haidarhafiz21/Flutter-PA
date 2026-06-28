import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/book_service.dart';
import '../../widgets/kejaksaan_ui.dart';
import 'read_book_page.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  List books = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    final data = await BookService.getDigitalBooks();
    if (!mounted) return;
    setState(() {
      books = data;
      loading = false;
    });
  }

  Widget bookCard(Map<String, dynamic> book) {
    final coverUrl = ApiConfig.fileUrl(book['cover_buku']?.toString());

    return KCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      radius: 22,
      borderGold: true,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              coverUrl,
              width: 64,
              height: 88,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: KMotion.normal,
                  curve: KMotion.curve,
                  child: child,
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 88,
                color: KColors.card2,
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 38,
                  color: KColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['judul'] ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  book['penulis'] ?? "-",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: KColors.softText),
                ),
                const SizedBox(height: 7),
                Text(
                  book['deskripsi'] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: KColors.gold,
                foregroundColor: KColors.dark,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  KMotion.route(
                    ReadBookPage(
                      bookId: int.tryParse((book['id'] ?? '').toString()),
                      filePdf: book['file_pdf']?.toString(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chrome_reader_mode_rounded, size: 18),
              label: const Text(
                "Baca",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingView() {
    return ListView.builder(
      key: const ValueKey('books-loading'),
      padding: const EdgeInsets.only(top: 10, bottom: 18),
      itemCount: 5,
      itemBuilder: (context, index) {
        return KStaggeredItem(
          index: index,
          child: KCard(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            radius: 22,
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 12,
                        width: 130,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget emptyView() {
    return const Center(
      key: ValueKey('books-empty'),
      child: Text(
        "Belum ada buku digital",
        style: TextStyle(color: KColors.softText, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget listView() {
    return ListView.builder(
      key: const ValueKey('books-list'),
      padding: const EdgeInsets.only(top: 10, bottom: 18),
      itemCount: books.length,
      itemBuilder: (context, i) {
        return KStaggeredItem(
          index: i,
          child: bookCard(Map<String, dynamic>.from(books[i])),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.bg,
      appBar: AppBar(title: const Text("Perpustakaan Digital")),
      body: AnimatedSwitcher(
        duration: KMotion.normal,
        switchInCurve: KMotion.curve,
        switchOutCurve: Curves.easeInCubic,
        child: loading
            ? loadingView()
            : books.isEmpty
                ? emptyView()
                : listView(),
      ),
    );
  }
}
