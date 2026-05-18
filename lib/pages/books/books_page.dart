import 'package:flutter/material.dart';
import '../../services/book_service.dart';
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
    setState(() {
      books = data;
      loading = false;
    });
  }

  Widget bookCard(Map book) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            /// 🔥 COVER
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                "http://192.168.1.2:3000/${book['cover_buku']}",
                width: 60,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.book, size: 50),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['judul'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(book['penulis'] ?? "-"),
                  const SizedBox(height: 5),
                  Text(
                    book['deskripsi'] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReadBookPage(bookId: book['id']),
                  ),
                );
              },
              child: const Text("Baca"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perpustakaan Digital")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, i) {
                return bookCard(books[i]);
              },
            ),
    );
  }
}