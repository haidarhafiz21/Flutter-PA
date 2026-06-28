import 'package:flutter/material.dart';

import '../../services/book_service.dart';
import '../../services/request_book_service.dart';
import '../../widgets/kejaksaan_ui.dart';
import 'riwayat_request_buku_page.dart';

class RequestBukuPage extends StatefulWidget {
  final int userId;

  const RequestBukuPage({
    super.key,
    required this.userId,
  });

  @override
  State<RequestBukuPage> createState() => _RequestBukuPageState();
}

class _RequestBukuPageState extends State<RequestBukuPage> {
  final judulController = TextEditingController();
  final penulisController = TextEditingController();
  final penerbitController = TextEditingController();
  final tahunController = TextEditingController();
  final alasanController = TextEditingController();

  bool loading = false;
  String kategoriRak = "Pidana";

  static const List<String> fallbackKategoriList = [
    "Peraturan Kejaksaan",
    "Pidana",
    "Perdata",
    "Perundang-Undangan",
    "Tata Negara",
    "Majalah & Publikasi",
    "Referensi & Biografi",
    "Ekonomi",
    "HAM",
    "Hukum Islam",
    "Hukum Internasional",
    "Motivasi",
    "Pariwisata & Daerah",
  ];

  List<String> kategoriList = fallbackKategoriList;

  @override
  void initState() {
    super.initState();
    loadKategoriRak();
  }

  Future<void> loadKategoriRak() async {
    final racks = await BookService.getAllRacks();

    if (!mounted || racks.isEmpty) return;

    final names = racks
        .map((item) => Map<String, dynamic>.from(item))
        .map((item) => (item['nama_rak'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();

    if (names.isEmpty) return;

    setState(() {
      kategoriList = names;
      if (!kategoriList.contains(kategoriRak)) {
        kategoriRak = kategoriList.first;
      }
    });
  }

  @override
  void dispose() {
    judulController.dispose();
    penulisController.dispose();
    penerbitController.dispose();
    tahunController.dispose();
    alasanController.dispose();
    super.dispose();
  }

  Future<void> submitRequest() async {
    if (judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul buku wajib diisi")),
      );
      return;
    }

    setState(() => loading = true);

    final result = await RequestBookService.createRequest(
      userId: widget.userId,
      judulBuku: judulController.text.trim(),
      penulis: penulisController.text.trim(),
      penerbit: penerbitController.text.trim(),
      tahunTerbit: tahunController.text.trim(),
      kategoriRak: kategoriRak,
      alasan: alasanController.text.trim(),
    );

    if (!mounted) return;

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"] ?? "Request buku diproses"),
      ),
    );

    if (result["success"] == true) {
      judulController.clear();
      penulisController.clear();
      penerbitController.clear();
      tahunController.clear();
      alasanController.clear();
    }
  }

  Widget inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: KColors.softText),
          prefixIcon: Icon(icon, color: KColors.gold),
          filled: true,
          fillColor: KColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: KColors.gold.withOpacity(0.35),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: KColors.gold),
          ),
        ),
      ),
    );
  }

  Widget kategoriDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: kategoriRak,
        dropdownColor: KColors.card,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "Kategori Rak",
          labelStyle: const TextStyle(color: KColors.softText),
          prefixIcon: const Icon(Icons.category_rounded, color: KColors.gold),
          filled: true,
          fillColor: KColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: KColors.gold.withOpacity(0.35),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: KColors.gold),
          ),
        ),
        items: kategoriList.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => kategoriRak = value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.bg,
      body: Column(
        children: [
          KHeader(
            title: "Request Buku",
            subtitle: "Usulkan buku yang dibutuhkan peminjam",
            trailing: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                KCard(
                  borderGold: true,
                  radius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Form Usulan Buku",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Isi data buku sesuai kebutuhan perpustakaan.",
                        style: TextStyle(
                          color: KColors.softText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      inputField(
                        label: "Judul Buku",
                        controller: judulController,
                        icon: Icons.menu_book_rounded,
                      ),
                      inputField(
                        label: "Penulis",
                        controller: penulisController,
                        icon: Icons.person_rounded,
                      ),
                      inputField(
                        label: "Penerbit",
                        controller: penerbitController,
                        icon: Icons.business_rounded,
                      ),
                      inputField(
                        label: "Tahun Terbit",
                        controller: tahunController,
                        icon: Icons.calendar_month_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      kategoriDropdown(),
                      inputField(
                        label: "Alasan Mengusulkan Buku",
                        controller: alasanController,
                        icon: Icons.edit_note_rounded,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 6),
                      KButton(
                        text: loading ? "Mengirim..." : "Kirim Request",
                        icon: Icons.send_rounded,
                        loading: loading,
                        onTap: loading ? null : submitRequest,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KColors.gold,
                    side: const BorderSide(color: KColors.gold),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RiwayatRequestBukuPage(userId: widget.userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded),
                  label: const Text(
                    "Lihat Riwayat Request",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
