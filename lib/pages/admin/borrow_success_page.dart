import 'package:flutter/material.dart';

class BorrowSuccessPage extends StatelessWidget {
  final String nama;
  final String judulBuku;
  final String tanggalKembali;

  const BorrowSuccessPage({
    super.key,
    required this.nama,
    required this.judulBuku,
    required this.tanggalKembali,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Peminjaman Berhasil")),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 80),
                const SizedBox(height: 20),
                Text("Peminjaman Berhasil",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text("Nama: $nama"),
                Text("Buku: $judulBuku"),
                Text("Kembali: $tanggalKembali"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(
                        context, (route) => route.isFirst);
                  },
                  child: const Text("Selesai"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}