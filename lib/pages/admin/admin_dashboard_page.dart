import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/notification_service.dart';
import '../../widgets/kejaksaan_ui.dart';

import 'borrow_list_page.dart';
import 'bukti_peminjaman_page.dart';
import 'history_pembayaran_page.dart';
import 'history_pengembalian_page.dart';
import 'request_buku_admin_page.dart';
import 'scan_anggota_page.dart';
import 'select_member_page.dart';
import 'verifikasi_pembayaran_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final String nama;
  final int userId;
  final String fotoWajah;

  const AdminDashboardPage({
    super.key,
    required this.nama,
    required this.userId,
    required this.fotoWajah,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

Uint8List? decodeAdminImage(String base64String) {
  try {
    if (base64String.isEmpty) return null;
    if (base64String.contains(',')) {
      base64String = base64String.split(',').last;
    }
    return base64Decode(base64String);
  } catch (_) {
    return null;
  }
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int aktif = 0;
  int terlambat = 0;
  bool loading = true;

  List returnReminder = [];

  @override
  void initState() {
    super.initState();
    loadStats();
    loadReturnReminder();
  }

  Future<void> loadStats() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/borrows/stats"),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (!mounted) return;

      setState(() {
        aktif = int.tryParse((data["aktif"] ?? 0).toString()) ?? 0;
        terlambat = int.tryParse((data["terlambat"] ?? 0).toString()) ?? 0;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        aktif = 0;
        terlambat = 0;
        loading = false;
      });
    }
  }

  Future<void> loadReturnReminder() async {
    final result = await NotificationService.getAdminNotifications(
      widget.userId,
    );

    if (!mounted) return;

    setState(() {
      returnReminder = result;
    });
  }

  void bukaPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      loadStats();
      loadReturnReminder();
    });
  }

  int unreadNotificationCount() {
    return returnReminder.where((item) {
      final notif = Map<String, dynamic>.from(item);
      return notif["is_read"] != true;
    }).length;
  }

  String notifTitle(Map notif) {
    return (notif["title"] ??
            notif["judul"] ??
            notif["label"] ??
            "Notifikasi Admin")
        .toString();
  }

  String notifMessage(Map notif) {
    return (notif["message"] ??
            notif["pesan"] ??
            notif["judul_buku"] ??
            "Ada informasi terbaru untuk admin.")
        .toString();
  }

  String notifDate(Map notif) {
    final raw = (notif["created_at"] ?? notif["tanggal_target"] ?? "")
        .toString();

    if (raw.isEmpty) return "-";

    try {
      final dt = DateTime.parse(raw).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return raw;
    }
  }

  IconData notifIcon(Map notif) {
    final text =
        "${notif["title"] ?? ""} ${notif["judul"] ?? ""} ${notif["message"] ?? ""} ${notif["pesan"] ?? ""}"
            .toLowerCase();

    if (text.contains("terlambat")) return Icons.warning_rounded;
    if (text.contains("h-2")) return Icons.access_time_filled_rounded;
    if (text.contains("h-1")) return Icons.notifications_active_rounded;
    if (text.contains("hari ini")) return Icons.today_rounded;
    if (text.contains("pembayaran") || text.contains("denda")) {
      return Icons.payments_rounded;
    }
    if (text.contains("request")) return Icons.library_add_rounded;

    return Icons.notifications_rounded;
  }

  Future<void> markOneNotificationAsRead(
    Map notif,
    StateSetter setSheetState,
  ) async {
    final id = int.tryParse("${notif["id"]}") ?? 0;
    final isRead = notif["is_read"] == true;

    if (id == 0 || isRead) return;

    await NotificationService.markAsRead(id);
    final updated = await NotificationService.getAdminNotifications(
      widget.userId,
    );

    if (!mounted) return;

    setState(() {
      returnReminder = updated;
    });

    setSheetState(() {});
  }

  Future<void> markAllNotificationsAsRead(StateSetter setSheetState) async {
    await NotificationService.markAllAsRead(widget.userId);
    final updated = await NotificationService.getAdminNotifications(
      widget.userId,
    );

    if (!mounted) return;

    setState(() {
      returnReminder = updated;
    });

    setSheetState(() {});
  }

  void showReturnNotification() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final unreadCount = returnReminder.where((item) {
              final notif = Map<String, dynamic>.from(item);
              return notif["is_read"] != true;
            }).length;

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.84,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 55,
                    height: 5,
                    decoration: BoxDecoration(
                      color: KColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Notifikasi",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          "$unreadCount belum dibaca",
                          style: const TextStyle(
                            color: KColors.gold,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            markAllNotificationsAsRead(setSheetState);
                          },
                          icon: const Icon(Icons.done_all_rounded),
                          label: const Text(
                            "Tandai Semua Sudah Dibaca",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: KColors.gold,
                            side: const BorderSide(color: KColors.gold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: returnReminder.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                "Belum ada notifikasi.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: KColors.softText,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            itemCount: returnReminder.length,
                            itemBuilder: (context, index) {
                              final item = Map<String, dynamic>.from(
                                returnReminder[index],
                              );
                              final isRead = item["is_read"] == true;

                              return InkWell(
                                onTap: () {
                                  markOneNotificationAsRead(
                                    item,
                                    setSheetState,
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: isRead ? 0.48 : 1,
                                  child: KCard(
                                    borderGold: !isRead,
                                    margin: const EdgeInsets.only(bottom: 14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            gradient: isRead
                                                ? null
                                                : KGradient.gold,
                                            color: isRead
                                                ? KColors.card2
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          child: Icon(
                                            isRead
                                                ? Icons.done_all_rounded
                                                : notifIcon(item),
                                            color: isRead
                                                ? KColors.softText
                                                : KColors.dark,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                notifTitle(item),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isRead
                                                      ? KColors.softText
                                                      : Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                notifMessage(item),
                                                maxLines: 3,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: KColors.softText,
                                                  fontSize: 13,
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                notifDate(item),
                                                style: const TextStyle(
                                                  color: KColors.gold,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget statCard({
    required String title,
    required String subtitle,
    required int value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: KCard(
        padding: const EdgeInsets.all(16),
        radius: 26,
        onTap: onTap,
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return KCard(
      margin: const EdgeInsets.only(bottom: 14),
      radius: 24,
      padding: const EdgeInsets.all(14),
      borderGold: true,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: KGradient.gold,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: KColors.dark, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KColors.softText,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: KColors.gold,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    final bytes = decodeAdminImage(widget.fotoWajah);
    final unreadCount = unreadNotificationCount();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      decoration: const BoxDecoration(
        gradient: KGradient.main,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KColors.gold, width: 3),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                child: bytes == null
                    ? Text(
                        widget.nama.isNotEmpty
                            ? widget.nama[0].toUpperCase()
                            : "A",
                        style: const TextStyle(
                          fontSize: 24,
                          color: KColors.dark,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.nama,
                    style: const TextStyle(
                      color: KColors.softText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Perpustakaan Kejaksaan",
                    style: TextStyle(
                      color: KColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                InkWell(
                  onTap: showReturnNotification,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: KColors.gold.withOpacity(0.65),
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: KColors.gold,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: KColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          statCard(
            title: "Aktif",
            subtitle: "Sedang dipinjam",
            value: aktif,
            icon: Icons.menu_book_rounded,
            color: KColors.green,
            onTap: () => bukaPage(
              const BorrowListPage(type: "active"),
            ),
          ),
          const SizedBox(width: 14),
          statCard(
            title: "Terlambat",
            subtitle: "Perlu ditindaklanjuti",
            value: terlambat,
            icon: Icons.warning_rounded,
            color: KColors.danger,
            onTap: () => bukaPage(
              const BorrowListPage(type: "late"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Menu Admin", style: KText.section),
          const SizedBox(height: 14),
          menuTile(
            icon: Icons.badge_rounded,
            title: "Scan Anggota",
            subtitle: "Scan QR kartu anggota untuk melihat data KTP.",
            onTap: () => bukaPage(
              ScanAnggotaPage(adminId: widget.userId),
            ),
          ),
          menuTile(
            icon: Icons.fact_check_rounded,
            title: "Bukti Peminjaman",
            subtitle: "Lihat arsip bukti scan anggota peminjam.",
            onTap: () => bukaPage(
              const BuktiPeminjamanPage(),
            ),
          ),
          menuTile(
            icon: Icons.qr_code_scanner_rounded,
            title: "Scan Peminjaman Buku",
            subtitle: "Scan barcode untuk memproses pengambilan buku.",
            onTap: () => bukaPage(
              const SelectMemberPage(type: "borrow"),
            ),
          ),
          menuTile(
            icon: Icons.assignment_return_rounded,
            title: "Scan Pengembalian Buku",
            subtitle: "Kelola pengembalian buku aktif dan terlambat.",
            onTap: () => bukaPage(
              const BorrowListPage(type: "active"),
            ),
          ),
          menuTile(
            icon: Icons.payments_rounded,
            title: "Verifikasi Pembayaran",
            subtitle: "Periksa pembayaran denda online maupun cash.",
            onTap: () => bukaPage(
              const VerifikasiPembayaranPage(),
            ),
          ),
          menuTile(
            icon: Icons.library_add_rounded,
            title: "Request Buku",
            subtitle: "Setujui atau tolak usulan buku dari peminjam.",
            onTap: () => bukaPage(
              RequestBukuAdminPage(adminId: widget.userId),
            ),
          ),
          menuTile(
            icon: Icons.receipt_long_rounded,
            title: "History Pembayaran Denda",
            subtitle: "Lihat semua riwayat pembayaran denda.",
            onTap: () => bukaPage(
              const HistoryPembayaranPage(),
            ),
          ),
          menuTile(
            icon: Icons.history_rounded,
            title: "History Pengembalian Buku",
            subtitle: "Lihat buku yang sudah berhasil dikembalikan.",
            onTap: () => bukaPage(
              const HistoryPengembalianPage(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.bg,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await loadStats();
                await loadReturnReminder();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  buildHeader(),
                  const SizedBox(height: 22),
                  buildSummary(),
                  const SizedBox(height: 28),
                  buildMenu(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }
}
