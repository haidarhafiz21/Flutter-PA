import 'package:flutter/material.dart';
import 'home/home_page.dart';
import 'borrow/borrow_status_page.dart';
import 'riwayat/riwayat_page.dart';
import 'profil/profil_page.dart';

class MainNavigation extends StatefulWidget {
  final int userId;
  final String role;
  final String nama;
  final String fotoWajah;

  const MainNavigation({
    super.key,
    required this.userId,
    required this.role,
    required this.nama,
    required this.fotoWajah,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  late final List pages = [
    HomePage(
      userId: widget.userId,
      role: widget.role,
      nama: widget.nama,
      fotoWajah: widget.fotoWajah,
    ),
    BorrowStatusPage(userId: widget.userId),
    RiwayatPage(userId: widget.userId),
    ProfilPage(
      userId: widget.userId,
      fotoWajah: widget.fotoWajah,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Peminjaman",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Riwayat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}