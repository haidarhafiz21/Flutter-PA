import 'package:flutter/material.dart';
import '../widgets/kejaksaan_ui.dart';
import 'home/home_page.dart';
import 'borrow/borrow_status_page.dart';
import 'riwayat/riwayat_page.dart';
import 'profil/profil_page.dart';

class MainNavigation extends StatefulWidget {
  final int userId;
  final String role;
  final String nama;
  final String fotoWajah;
  final String email; // 🔧 baru

  const MainNavigation({
    super.key,
    required this.userId,
    required this.role,
    required this.nama,
    required this.fotoWajah,
    this.email = "", // 🔧 default "" agar aman / tidak error
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  late String fotoWajah;

  @override
  void initState() {
    super.initState();
    fotoWajah = widget.fotoWajah;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        userId: widget.userId,
        role: widget.role,
        nama: widget.nama,
        fotoWajah: fotoWajah,
      ),
      BorrowStatusPage(userId: widget.userId),
      RiwayatPage(userId: widget.userId),
      ProfilPage(
        userId: widget.userId,
        fotoWajah: fotoWajah,
        email: widget.email, // 🔧 teruskan email ke ProfilPage
        nama: widget.nama,   // 🔧 teruskan nama asli ke ProfilPage
        onFotoUpdated: (value) {
          setState(() {
            fotoWajah = value;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: KColors.bg,
      body: AnimatedSwitcher(
        duration: KMotion.normal,
        reverseDuration: KMotion.fast,
        switchInCurve: KMotion.curve,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: KMotion.curve,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.02),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(currentIndex),
          child: pages[currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: KColors.dark,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            backgroundColor: KColors.dark,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedItemColor: KColors.gold,
            unselectedItemColor: Colors.white54,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            onTap: (i) {
              if (i == currentIndex) return;
              setState(() => currentIndex = i);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: "Beranda",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded),
                label: "Peminjaman",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: "Riwayat",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: "Profil",
              ),
            ],
          ),
        ),
      ),
    );
  }
}