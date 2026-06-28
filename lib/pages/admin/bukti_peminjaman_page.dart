import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/bukti_peminjaman_service.dart';
import '../../widgets/kejaksaan_ui.dart';

class BuktiPeminjamanPage extends StatefulWidget {
  const BuktiPeminjamanPage({super.key});

  @override
  State<BuktiPeminjamanPage> createState() => _BuktiPeminjamanPageState();
}

class _BuktiPeminjamanPageState extends State<BuktiPeminjamanPage> {
  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Uint8List? decodeBase64Image(String? value) {
    try {
      if (value == null || value.isEmpty) return null;
      if (value.contains(',')) {
        value = value.split(',').last;
      }
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final result = await BuktiPeminjamanService.getAllBukti();

    if (!mounted) return;

    setState(() {
      data = result;
      loading = false;
    });
  }

  String formatTanggal(String? raw) {
    if (raw == null || raw.isEmpty) return "-";

    try {
      final dt = DateTime.parse(raw).toLocal();

      const bulan = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];

      return "${dt.day} ${bulan[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "-";
    }
  }

  void showImagePreview({
    required String title,
    required Uint8List? imageBytes,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: KColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: KColors.gold),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 420,
                  ),
                  decoration: BoxDecoration(
                    color: KColors.bg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: imageBytes == null
                      ? const SizedBox(
                          height: 220,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: KColors.gold,
                              size: 60,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                KButton(
                  text: "Tutup",
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget imageButton({
    required String title,
    required IconData icon,
    required Uint8List? imageBytes,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          showImagePreview(title: title, imageBytes: imageBytes);
        },
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: KColors.gold,
          side: const BorderSide(color: KColors.gold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget buktiCard(Map item) {
    final fotoWajah = decodeBase64Image(item["foto_wajah"]?.toString());
    final fotoKtp = decodeBase64Image(item["foto_ktp"]?.toString());

    return KCard(
      borderGold: true,
      radius: 26,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                backgroundImage:
                    fotoWajah != null ? MemoryImage(fotoWajah) : null,
                child: fotoWajah == null
                    ? const Icon(Icons.person, color: KColors.dark)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["nama_peminjam"] ?? "-",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item["email"] ?? "-",
                      style: const TextStyle(
                        color: KColors.softText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID Anggota: ${item["user_id"] ?? "-"}",
                      style: const TextStyle(
                        color: KColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Alamat",
            style: const TextStyle(
              color: KColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item["alamat"] ?? "-",
            style: const TextStyle(
              color: KColors.softText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: KColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KColors.gold.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: KColors.gold,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Bukti tersimpan: ${formatTanggal(item["created_at"]?.toString())}",
                    style: const TextStyle(
                      color: KColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              imageButton(
                title: "Foto Wajah",
                icon: Icons.person_rounded,
                imageBytes: fotoWajah,
              ),
              const SizedBox(width: 10),
              imageButton(
                title: "Foto KTP",
                icon: Icons.badge_rounded,
                imageBytes: fotoKtp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "Belum ada bukti peminjaman yang tersimpan.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: KColors.softText,
            fontSize: 15,
            height: 1.4,
          ),
        ),
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
            title: "Bukti Peminjaman",
            subtitle: "Arsip bukti scan anggota dan identitas peminjam",
            trailing: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: KColors.gold),
                  )
                : data.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(18),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            return buktiCard(
                              Map<String, dynamic>.from(data[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}