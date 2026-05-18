import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class ReadBookPage extends StatefulWidget {
  final int bookId;

  const ReadBookPage({super.key, required this.bookId});

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
      final url = "${ApiConfig.readBook}/${widget.bookId}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Gagal membuka PDF");
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/book_${widget.bookId}.pdf");

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
        const SnackBar(content: Text("Gagal membuka buku")),
      );
    }
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