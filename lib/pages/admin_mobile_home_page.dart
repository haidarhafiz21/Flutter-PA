import 'package:flutter/material.dart';

class AdminMobileHomePage extends StatelessWidget {
  final String nama;

  const AdminMobileHomePage({super.key, required this.nama});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Mobile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, $nama',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama sesuai KTP',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan Buku Peminjaman'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('Scan Buku Pengembalian'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifikasi Keterlambatan'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}