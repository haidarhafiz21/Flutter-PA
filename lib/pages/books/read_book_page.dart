import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class ReadBookPage extends StatefulWidget {
  final int? bookId;
  final String? filePdf;

  const ReadBookPage({
    super.key,
    this.bookId,
    this.filePdf,
  });

  @override
  State<ReadBookPage> createState() => _ReadBookPageState();
}

class _ReadBookPageState extends State<ReadBookPage> {
  String? localPath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    downloadFile();
  }

  Future<void> downloadFile() async {
    try {
      final url = pdfUrl();
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || !isPdfResponse(response)) {
        throw Exception("Status ${response.statusCode}");
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = widget.bookId != null
          ? "book_${widget.bookId}.pdf"
          : "book_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (!mounted) return;
      setState(() {
        localPath = file.path;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka PDF")),
      );
    }
  }

  String pdfUrl() {
    // Utamakan file langsung dari /uploads/ (sudah terbukti bisa dibuka)
    final pdfPath = widget.filePdf?.trim() ?? "";
    if (pdfPath.isNotEmpty) {
      return ApiConfig.fileUrl(pdfPath);
    }
    // Cadangan: endpoint baca-by-id
    final id = widget.bookId;
    if (id != null && id > 0) {
      return "${ApiConfig.readBook}/$id";
    }
    throw Exception("Path PDF kosong");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Baca PDF")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : localPath == null
              ? const Center(child: Text("PDF tidak ditemukan"))
              : PDFView(filePath: localPath!),
    );
  }
}