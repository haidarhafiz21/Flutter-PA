import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../widgets/kejaksaan_ui.dart';

class KartuAnggotaPage extends StatelessWidget {
  final int userId;
  final String nama;
  final String role;

  const KartuAnggotaPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = "MEMBER:$userId";

    return Scaffold(
      backgroundColor: KColors.bg,
      body: Column(
        children: [
          KHeader(
            title: "Kartu Anggota",
            subtitle: "Gunakan QR ini saat mengambil buku",
            trailing: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                KCard(
                  borderGold: true,
                  radius: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: KGradient.gold,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.badge_rounded,
                          color: KColors.dark,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        nama,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "ID Anggota : $userId",
                        style: const TextStyle(
                          color: KColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        role,
                        style: const TextStyle(
                          color: KColors.softText,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 250,
                          backgroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: KColors.gold.withOpacity(0.15),
                          border: Border.all(
                            color: KColors.gold.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          qrData,
                          style: const TextStyle(
                            color: KColors.gold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Tunjukkan QR ini kepada admin perpustakaan saat pengambilan buku. Admin akan melakukan scan untuk memverifikasi identitas peminjam.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: KColors.softText,
                    height: 1.5,
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