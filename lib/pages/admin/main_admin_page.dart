import 'package:flutter/material.dart';
import '../../widgets/kejaksaan_ui.dart';

import 'admin_dashboard_page.dart';
import 'admin_profile_page.dart';

class MainAdminPage extends StatefulWidget {
  final String nama;
  final int userId;
  final String fotoWajah;

  const MainAdminPage({
    super.key,
    required this.nama,
    required this.userId,
    required this.fotoWajah,
  });

  @override
  State<MainAdminPage> createState() => _MainAdminPageState();
}

class _MainAdminPageState extends State<MainAdminPage> {
  int selectedIndex = 0;
  late String fotoWajah;

  @override
  void initState() {
    super.initState();
    fotoWajah = widget.fotoWajah;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminDashboardPage(
        nama: widget.nama,
        userId: widget.userId,
        fotoWajah: fotoWajah,
      ),
      AdminProfilePage(
        nama: widget.nama,
        userId: widget.userId,
        fotoWajah: fotoWajah,
        onFotoUpdated: (value) {
          setState(() {
            fotoWajah = value;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: KColors.bg,
      body: pages[selectedIndex],
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
            currentIndex: selectedIndex,
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
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: "Beranda",
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