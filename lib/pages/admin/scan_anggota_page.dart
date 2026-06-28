import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/bukti_peminjaman_service.dart';
import '../../widgets/kejaksaan_ui.dart';

class ScanAnggotaPage extends StatefulWidget {
  final int adminId;

  const ScanAnggotaPage({
    super.key,
    required this.adminId,
  });

  @override
  State<ScanAnggotaPage> createState() => _ScanAnggotaPageState();
}

class _ScanAnggotaPageState extends State<ScanAnggotaPage> {
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool processing = false;
  bool scanned = false;
  bool saving = false;

  Map<String, dynamic>? userData;

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

  Future<void> onDetect(BarcodeCapture capture) async {
    if (processing || scanned) return;

    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    int userId = 0;

    if (raw.startsWith("MEMBER:")) {
      userId = int.tryParse(raw.replaceAll("MEMBER:", "")) ?? 0;
    } else {
      userId = int.tryParse(raw) ?? 0;
    }

    if (userId == 0) {
      showMessage("QR anggota tidak valid");
      return;
    }

    setState(() {
      processing = true;
      scanned = true;
    });

    await scannerController.stop();
    await loadUserDetail(userId);
  }

  Future<void> loadUserDetail(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.userDetail}/$userId"),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (!mounted) return;

      if (data["success"] == true && data["data"] != null) {
        setState(() {
          userData = Map<String, dynamic>.from(data["data"]);
          processing = false;
        });
      } else {
        setState(() {
          processing = false;
          scanned = false;
        });

        await scannerController.start();
        showMessage(data["message"] ?? "Data anggota tidak ditemukan");
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        processing = false;
        scanned = false;
      });

      await scannerController.start();
      showMessage("Gagal terhubung ke server");
    }
  }

  Future<void> simpanBuktiPeminjaman() async {
    if (userData == null || saving) return;

    final data = userData!;

    final userId = int.tryParse("${data["id"] ?? 0}") ?? 0;
    final nama = (data["nama_lengkap"] ?? "-").toString();
    final email = (data["email"] ?? "-").toString();
    final alamat = (data["alamat"] ?? "-").toString();
    final fotoWajah = (data["foto_wajah"] ?? "").toString();
    final fotoKtp = (data["foto_ktp"] ?? "").toString();

    if (userId == 0) {
      showMessage("ID anggota tidak valid");
      return;
    }

    setState(() => saving = true);

    final result = await BuktiPeminjamanService.createBukti(
      userId: userId,
      adminId: widget.adminId,
      namaPeminjam: nama,
      email: email,
      alamat: alamat,
      fotoWajah: fotoWajah,
      fotoKtp: fotoKtp,
    );

    if (!mounted) return;

    setState(() => saving = false);

    showMessage(
      result["message"]?.toString() ?? "Bukti peminjaman berhasil diproses",
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> resetScan() async {
    setState(() {
      userData = null;
      scanned = false;
      processing = false;
      saving = false;
    });

    await scannerController.start();
  }

  Widget scannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: scannerController,
          onDetect: onDetect,
        ),
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: KColors.gold, width: 4),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 36,
          child: KCard(
            borderGold: true,
            child: const Text(
              "Arahkan kamera ke QR Kartu Anggota peminjam.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ),
        if (processing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: KColors.gold),
            ),
          ),
      ],
    );
  }

  Widget imageBox({
    required String title,
    required Uint8List? imageBytes,
    required IconData icon,
  }) {
    return KCard(
      borderGold: true,
      radius: 24,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KText.section),
          const SizedBox(height: 12),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: KColors.card2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: KColors.gold.withOpacity(0.35),
              ),
            ),
            child: imageBytes == null
                ? Icon(icon, color: KColors.gold, size: 54)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget detailView() {
    final data = userData!;
    final fotoWajah = decodeBase64Image(data["foto_wajah"]?.toString());
    final fotoKtp = decodeBase64Image(data["foto_ktp"]?.toString());

    return Scaffold(
      backgroundColor: KColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              KHeader(
                title: "Detail Anggota",
                subtitle: "Data hasil scan kartu anggota",
                trailing: IconButton(
                  onPressed: resetScan,
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    KCard(
                      borderGold: true,
                      radius: 26,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white,
                            backgroundImage: fotoWajah != null
                                ? MemoryImage(fotoWajah)
                                : null,
                            child: fotoWajah == null
                                ? const Icon(
                                    Icons.person,
                                    color: KColors.dark,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data["nama_lengkap"] ?? "-",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  data["email"] ?? "-",
                                  style:
                                      const TextStyle(color: KColors.softText),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "ID: ${data["id"] ?? "-"}",
                                  style: const TextStyle(
                                    color: KColors.gold,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    KCard(
                      borderGold: true,
                      radius: 26,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Alamat", style: KText.section),
                          const SizedBox(height: 8),
                          Text(
                            data["alamat"] ?? "-",
                            style: const TextStyle(
                              color: KColors.softText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    imageBox(
                      title: "Foto KTP",
                      imageBytes: fotoKtp,
                      icon: Icons.badge_rounded,
                    ),
                    imageBox(
                      title: "Foto Wajah",
                      imageBytes: fotoWajah,
                      icon: Icons.person_rounded,
                    ),
                    KButton(
                      text: saving
                          ? "Menyimpan Bukti..."
                          : "Simpan Bukti Peminjaman",
                      icon: Icons.save_rounded,
                      loading: saving,
                      onTap: saving ? null : simpanBuktiPeminjaman,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: saving ? null : resetScan,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text(
                        "Scan Anggota Lain",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KColors.gold,
                        side: const BorderSide(color: KColors.gold),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
          if (saving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: KColors.gold),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userData != null) return detailView();

    return Scaffold(
      backgroundColor: KColors.bg,
      appBar: AppBar(
        title: const Text("Scan Anggota"),
        backgroundColor: KColors.dark,
        foregroundColor: Colors.white,
      ),
      body: scannerView(),
    );
  }
}