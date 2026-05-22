import 'package:flutter/material.dart';
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
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.green,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Beranda",
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
