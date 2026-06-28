import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/book_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/kejaksaan_ui.dart';
import '../books/book_detail_page.dart';
import '../books/books_by_rak_page.dart';
import '../pickup/pickup_countdown_page.dart';
import '../request_buku/request_buku_page.dart';
import '../user/kartu_anggota_page.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String role;
  final String nama;
  final String fotoWajah;

  const HomePage({
    super.key,
    required this.userId,
    required this.role,
    required this.nama,
    required this.fotoWajah,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List recommendedBooks = [];
  List notifications = [];
  List<Map<String, dynamic>> rakList = [];

  // === DATA UNTUK FILTER TAHUN ===
  List<Map<String, dynamic>> allBooks = [];
  bool allBooksLoaded = false;
  bool loadingAllBooks = false;
  String selectedTahun = "Semua";
  List<String> tahunOptions = const ["Semua"];

  bool loading = true;
  bool bookingLoading = false;
  bool searchLoading = false;
  int currentBanner = 0;

  final TextEditingController searchController = TextEditingController();
  final PageController bannerController = PageController(
    viewportFraction: 0.92,
  );

  final List<Map<String, dynamic>> banners = const [
    {
      "title": "Membaca buku menambah ilmu dan membuka wawasan baru.",
    },
    {
      "title": "Semakin banyak membaca, semakin luas pengetahuan yang didapat.",
    },
    {
      "title": "Buku adalah sumber ilmu untuk belajar dan memahami banyak hal.",
    },
  ];

  static const List<String> fallbackRakList = [
    BookService.digitalRackName,
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

  Widget requestBukuCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: KCard(
        borderGold: true,
        radius: 24,
        onTap: () {
          Navigator.push(
            context,
            KMotion.route(RequestBukuPage(userId: widget.userId)),
          );
        },
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: KGradient.gold,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: KColors.dark,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Request Buku",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Usulkan buku yang belum tersedia di perpustakaan.",
                    style: TextStyle(
                      color: KColors.softText,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: KColors.gold,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget kartuAnggotaCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: KCard(
        borderGold: true,
        radius: 24,
        onTap: () {
          Navigator.push(
            context,
            KMotion.route(
              KartuAnggotaPage(
                userId: widget.userId,
                nama: widget.nama,
                role: widget.role,
              ),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: KGradient.gold,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.badge_rounded,
                color: KColors.dark,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kartu Anggota",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Tampilkan QR anggota untuk diverifikasi admin.",
                    style: TextStyle(
                      color: KColors.softText,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: KColors.gold,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadRacks().then((_) => loadAllBooks());
    loadRecommended();
    loadNotifications();
  }

  @override
  void dispose() {
    searchController.dispose();
    bannerController.dispose();
    super.dispose();
  }

  Uint8List safeBase64(String data) {
    try {
      if (data.contains(',')) {
        data = data.split(',').last;
      }
      return base64Decode(data);
    } catch (e) {
      return Uint8List(0);
    }
  }

  Future<void> loadRecommended() async {
    try {
      final data = await BookService.getRecommended(widget.role);
      if (!mounted) return;
      setState(() {
        recommendedBooks = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        recommendedBooks = [];
        loading = false;
      });
    }
  }

  Future<void> loadRacks() async {
    final data = await BookService.getAllRacks();
    final digitalBooks = await BookService.getDigitalBooks();
    if (!mounted) return;
    setState(() {
      rakList = data.isNotEmpty
          ? data.map((item) => Map<String, dynamic>.from(item)).toList()
          : fallbackRakList.map((nama) => {"nama_rak": nama}).toList();

      final digitalRackIndex = rakList.indexWhere(
        (rak) => BookService.isDigitalRack(
          (rak['nama_rak'] ?? '').toString(),
        ),
      );

      if (digitalRackIndex >= 0) {
        rakList[digitalRackIndex] = {
          ...rakList[digitalRackIndex],
          "nama_rak": BookService.digitalRackName,
          "total_buku": digitalBooks.isNotEmpty
              ? digitalBooks.length
              : int.tryParse(
                    (rakList[digitalRackIndex]['total_buku'] ?? 1).toString(),
                  ) ??
                  1,
        };
      } else {
        rakList.insert(0, {
          "nama_rak": BookService.digitalRackName,
          "tipe_rak": "publik",
          "total_buku": digitalBooks.isNotEmpty ? digitalBooks.length : 1,
        });
      }
    });
  }

  // === Kumpulkan semua buku dari semua rak untuk filter tahun ===
  Future<void> loadAllBooks() async {
    if (loadingAllBooks) return;
    if (!mounted) return;
    setState(() => loadingAllBooks = true);
    try {
      final racks = rakList.isNotEmpty
          ? rakList
          : fallbackRakList.map((nama) => {"nama_rak": nama}).toList();

      final List<Map<String, dynamic>> semua = [];
      final Set<String> seenIds = {};

      for (final rak in racks) {
        final namaRak = (rak['nama_rak'] ?? '').toString();
        if (namaRak.isEmpty) continue;
        final data = await BookService.getBooksByRack(namaRak, widget.role);
        for (final item in data) {
          final book = Map<String, dynamic>.from(item);
          book['nama_rak'] = namaRak;
          final id = (book['id'] ?? '').toString();
          if (id.isNotEmpty) {
            if (seenIds.contains(id)) continue;
            seenIds.add(id);
          }
          semua.add(book);
        }
      }

      final tahunSet = <String>{};
      for (final b in semua) {
        final t = (b['tahun_terbit'] ?? '').toString();
        if (t.isNotEmpty && t != 'null') tahunSet.add(t);
      }
      final tahunList = tahunSet.toList()..sort((a, b) => b.compareTo(a));

      if (!mounted) return;
      setState(() {
        allBooks = semua;
        tahunOptions = ["Semua", ...tahunList];
        allBooksLoaded = true;
        loadingAllBooks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingAllBooks = false);
    }
  }

  Future<void> loadNotifications() async {
    final result =
        await NotificationService.getUserNotifications(widget.userId);
    if (!mounted) return;
    setState(() {
      notifications = result;
    });
  }

  Future<void> refreshAll() async {
    await loadRacks();
    await loadAllBooks();
    await loadRecommended();
    await loadNotifications();
  }

  List<Map<String, dynamic>> visibleRacks() {
    final racks = rakList.isNotEmpty
        ? rakList
        : fallbackRakList.map((nama) => {"nama_rak": nama}).toList();
    return racks.where((rak) {
      if (BookService.isDigitalRack((rak['nama_rak'] ?? '').toString())) {
        return true;
      }
      final total = int.tryParse((rak['total_buku'] ?? 1).toString()) ?? 1;
      return total > 0;
    }).toList();
  }

  IconData rakIcon(String namaRak) {
    final name = namaRak.toLowerCase();
    if (name.contains("kejaksaan")) return Icons.account_balance;
    if (name.contains("pdf") || name.contains("online")) {
      return Icons.picture_as_pdf_rounded;
    }
    if (name.contains("pidana")) return Icons.gavel_rounded;
    if (name.contains("perdata")) return Icons.balance_rounded;
    if (name.contains("undang") || name.contains("regulasi")) {
      return Icons.article_rounded;
    }
    if (name.contains("tata") || name.contains("negara")) {
      return Icons.public_rounded;
    }
    if (name.contains("majalah") || name.contains("publikasi")) {
      return Icons.menu_book_rounded;
    }
    if (name.contains("referensi") || name.contains("biografi")) {
      return Icons.auto_stories_rounded;
    }
    if (name.contains("ekonomi")) return Icons.payments_rounded;
    if (name.contains("ham")) return Icons.diversity_3_rounded;
    if (name.contains("islam")) return Icons.account_balance_rounded;
    if (name.contains("internasional")) return Icons.language_rounded;
    if (name.contains("motivasi")) return Icons.lightbulb_rounded;
    if (name.contains("pariwisata") || name.contains("daerah")) {
      return Icons.travel_explore_rounded;
    }
    return Icons.category_rounded;
  }

  int unreadNotificationCount() {
    return notifications.where((item) {
      final notif = Map<String, dynamic>.from(item);
      return notif["is_read"] != true;
    }).length;
  }

  String notifTitle(Map notif) {
    return (notif["title"] ??
            notif["judul"] ??
            notif["tipe"] ??
            notif["type"] ??
            "Notifikasi")
        .toString();
  }

  String notifMessage(Map notif) {
    return (notif["message"] ??
            notif["pesan"] ??
            notif["keterangan"] ??
            notif["isi"] ??
            "Ada informasi terbaru dari perpustakaan.")
        .toString();
  }

  String notifDate(Map notif) {
    final raw = (notif["created_at"] ??
            notif["tanggal"] ??
            notif["tanggal_notifikasi"] ??
            "")
        .toString();
    if (raw.isEmpty) return "-";
    try {
      final dt = DateTime.parse(raw).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return raw;
    }
  }

  IconData notifIcon(Map notif) {
    final text =
        "${notif["title"] ?? ""} ${notif["judul"] ?? ""} ${notif["type"] ?? ""} ${notif["tipe"] ?? ""}"
            .toLowerCase();
    if (text.contains("terlambat")) return Icons.warning_rounded;
    if (text.contains("h-2")) return Icons.access_time_filled_rounded;
    if (text.contains("h-1")) return Icons.notifications_active_rounded;
    if (text.contains("hari ini")) return Icons.today_rounded;
    if (text.contains("pembayaran") || text.contains("denda")) {
      return Icons.payments_rounded;
    }
    if (text.contains("booking")) return Icons.event_busy_rounded;
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
    final updated = await NotificationService.getUserNotifications(
      widget.userId,
    );
    if (!mounted) return;
    setState(() {
      notifications = updated;
    });
    setSheetState(() {});
  }

  Future<void> markAllNotificationsAsRead(StateSetter setSheetState) async {
    await NotificationService.markAllAsRead(widget.userId);
    final updated = await NotificationService.getUserNotifications(
      widget.userId,
    );
    if (!mounted) return;
    setState(() {
      notifications = updated;
    });
    setSheetState(() {});
  }

  void showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final unreadCount = notifications.where((item) {
              final notif = Map<String, dynamic>.from(item);
              return notif["is_read"] != true;
            }).length;
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.84,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: KColors.gold,
                      borderRadius: BorderRadius.circular(30),
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
                    child: notifications.isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada notifikasi.",
                              style: TextStyle(color: KColors.softText),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notif = Map<String, dynamic>.from(
                                notifications[index],
                              );
                              final isRead = notif["is_read"] == true;
                              return InkWell(
                                onTap: () {
                                  markOneNotificationAsRead(
                                    notif,
                                    setSheetState,
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: isRead ? 0.48 : 1,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      gradient: isRead
                                          ? KGradient.card
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xff0E4A3A),
                                                Color(0xff063126),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isRead
                                            ? Colors.white.withOpacity(0.08)
                                            : KColors.gold,
                                        width: isRead ? 1 : 1.5,
                                      ),
                                      boxShadow: [
                                        if (!isRead)
                                          BoxShadow(
                                            color:
                                                KColors.gold.withOpacity(0.16),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            gradient:
                                                isRead ? null : KGradient.gold,
                                            color:
                                                isRead ? KColors.card2 : null,
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isRead
                                                  ? Colors.white
                                                      .withOpacity(0.08)
                                                  : KColors.gold
                                                      .withOpacity(0.6),
                                            ),
                                          ),
                                          child: Icon(
                                            isRead
                                                ? Icons.done_all_rounded
                                                : notifIcon(notif),
                                            color: isRead
                                                ? KColors.softText
                                                : KColors.dark,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      notifTitle(notif),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: isRead
                                                            ? KColors.softText
                                                            : Colors.white,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isRead)
                                                    Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: KColors.danger,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                notifMessage(notif),
                                                style: TextStyle(
                                                  color: isRead
                                                      ? KColors.softText
                                                          .withOpacity(0.65)
                                                      : KColors.softText,
                                                  height: 1.4,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Text(
                                                    notifDate(notif),
                                                    style: const TextStyle(
                                                      color: KColors.gold,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    isRead
                                                        ? "Sudah dibaca"
                                                        : "Belum dibaca",
                                                    style: TextStyle(
                                                      color: isRead
                                                          ? KColors.softText
                                                          : KColors.danger,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
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
    ).whenComplete(() async {
      await loadNotifications();
    });
  }

  Future<void> pinjamBuku(Map book) async {
    if (bookingLoading) return;
    final stok = int.tryParse((book['stok'] ?? 0).toString()) ?? 0;
    if (stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stok buku habis")),
      );
      return;
    }
    setState(() => bookingLoading = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.booking),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": book['id'],
        }),
      );
      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      if (!mounted) return;
      if (data["success"] == true) {
        final batasAmbilString = data["batas_ambil"]?.toString();
        if (batasAmbilString == null || batasAmbilString.isEmpty) {
          setState(() => bookingLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Batas ambil tidak ditemukan")),
          );
          return;
        }
        final batasAmbil = DateTime.parse(batasAmbilString).toLocal();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'borrow_pickup_deadline',
          batasAmbil.millisecondsSinceEpoch,
        );
        if (!mounted) return;
        setState(() => bookingLoading = false);
        Navigator.pushReplacement(
          context,
          KMotion.route(PickupCountdownPage(userId: widget.userId)),
        );
      } else {
        setState(() => bookingLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Booking gagal")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => bookingLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server")),
      );
    }
  }

  // === PENCARIAN (sudah menghormati filter tahun) ===
  Future<void> cariBuku(String keyword) async {
    final q = keyword.trim().toLowerCase();

    if (q.isEmpty) {
      if (selectedTahun != "Semua") {
        tampilkanHasilTahun(selectedTahun);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan kata kunci pencarian")),
      );
      return;
    }

    setState(() => searchLoading = true);
    try {
      List<Map<String, dynamic>> sumber;
      if (allBooksLoaded && allBooks.isNotEmpty) {
        sumber = allBooks;
      } else {
        final List<Map<String, dynamic>> kumpulan = [];
        final racks = rakList.isNotEmpty
            ? rakList
            : fallbackRakList.map((nama) => {"nama_rak": nama}).toList();
        for (final rak in racks) {
          final namaRak = (rak['nama_rak'] ?? '').toString();
          if (namaRak.isEmpty) continue;
          final data = await BookService.getBooksByRack(namaRak, widget.role);
          for (final item in data) {
            final book = Map<String, dynamic>.from(item);
            book['nama_rak'] = namaRak;
            kumpulan.add(book);
          }
        }
        sumber = kumpulan;
      }

      final hasil = sumber.where((book) {
        final judul = (book['judul'] ?? '').toString().toLowerCase();
        final penulis = (book['penulis'] ?? '').toString().toLowerCase();
        final penerbit = (book['penerbit'] ?? '').toString().toLowerCase();
        final tahun = (book['tahun_terbit'] ?? '').toString().toLowerCase();
        final kategori = (book['nama_rak'] ?? '').toString().toLowerCase();

        final cocokKeyword = judul.contains(q) ||
            penulis.contains(q) ||
            penerbit.contains(q) ||
            tahun.contains(q) ||
            kategori.contains(q);

        final cocokTahun = selectedTahun == "Semua" ||
            (book['tahun_terbit'] ?? '').toString() == selectedTahun;

        return cocokKeyword && cocokTahun;
      }).toList();

      if (!mounted) return;
      setState(() => searchLoading = false);
      showHasilSheet(hasil, judulSheet: "Hasil Pencarian");
    } catch (e) {
      if (!mounted) return;
      setState(() => searchLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mencari buku")),
      );
    }
  }

  // === TAMPILKAN BUKU BERDASARKAN TAHUN (terlama dulu) ===
  void tampilkanHasilTahun(String tahun) {
    if (!allBooksLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sedang menyiapkan data buku, coba lagi sebentar..."),
        ),
      );
      loadAllBooks();
      return;
    }

    final keyword = searchController.text.trim().toLowerCase();

    final hasil = allBooks.where((book) {
      final t = (book['tahun_terbit'] ?? '').toString();
      final cocokTahun = tahun == "Semua" || t == tahun;
      if (!cocokTahun) return false;
      if (keyword.isEmpty) return true;

      final judul = (book['judul'] ?? '').toString().toLowerCase();
      final penulis = (book['penulis'] ?? '').toString().toLowerCase();
      final penerbit = (book['penerbit'] ?? '').toString().toLowerCase();
      final kategori = (book['nama_rak'] ?? '').toString().toLowerCase();
      return judul.contains(keyword) ||
          penulis.contains(keyword) ||
          penerbit.contains(keyword) ||
          kategori.contains(keyword);
    }).toList();

    hasil.sort((a, b) {
      final ta = int.tryParse((a['tahun_terbit'] ?? '0').toString()) ?? 0;
      final tb = int.tryParse((b['tahun_terbit'] ?? '0').toString()) ?? 0;
      return ta.compareTo(tb);
    });

    showHasilSheet(
      hasil,
      judulSheet:
          tahun == "Semua" ? "Semua Tahun (terlama dulu)" : "Tahun $tahun",
    );
  }

  // === BOTTOM SHEET HASIL (dipakai pencarian & filter tahun) ===
  void showHasilSheet(
    List<Map<String, dynamic>> hasil, {
    String judulSheet = "Hasil Pencarian",
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: KColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        judulSheet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      "${hasil.length} buku",
                      style: const TextStyle(
                        color: KColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: hasil.isEmpty
                    ? const Center(
                        child: Text(
                          "Buku tidak ditemukan",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        itemCount: hasil.length,
                        itemBuilder: (context, index) {
                          final book = hasil[index];
                          final cover = ApiConfig.fileUrl(
                            book['cover_buku']?.toString(),
                          );
                          return KCard(
                            margin: const EdgeInsets.only(bottom: 14),
                            borderGold: true,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    cover,
                                    width: 62,
                                    height: 86,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        width: 62,
                                        height: 86,
                                        color: KColors.card2,
                                        child: const Icon(
                                          Icons.menu_book,
                                          color: KColors.gold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book['judul'] ?? "-",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        book['penulis'] ?? "-",
                                        style: const TextStyle(
                                          color: KColors.softText,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              book['nama_rak'] ?? "-",
                                              style: const TextStyle(
                                                color: KColors.gold,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          if ((book['tahun_terbit'] ?? '')
                                                  .toString()
                                                  .isNotEmpty &&
                                              (book['tahun_terbit'] ?? '')
                                                      .toString() !=
                                                  'null')
                                            Text(
                                              "Thn ${book['tahun_terbit']}",
                                              style: const TextStyle(
                                                color: KColors.softText,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: KColors.gold,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      KMotion.route(
                                        BookDetailPage(
                                          book: book,
                                          userId: widget.userId,
                                          role: widget.role,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
  }

  // === FILTER TAHUN (di bawah kolom pencarian, dengan ikon kalender) ===
  Widget buildYearFilter() {
    final safeSelected =
        tahunOptions.contains(selectedTahun) ? selectedTahun : "Semua";
    return KCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      radius: 22,
      borderGold: true,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: KGradient.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: KColors.dark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Tahun",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeSelected,
                dropdownColor: KColors.card,
                iconEnabledColor: KColors.gold,
                isExpanded: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                items: tahunOptions.map((tahun) {
                  return DropdownMenuItem<String>(
                    value: tahun,
                    child: Text(tahun),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedTahun = value);
                  tampilkanHasilTahun(value);
                },
              ),
            ),
          ),
          if (loadingAllBooks)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: KColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget header() {
    final imageBytes = safeBase64(widget.fotoWajah);
    final unreadCount = unreadNotificationCount();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: const BoxDecoration(
        gradient: KGradient.main,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(38),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      imageBytes.isNotEmpty ? MemoryImage(imageBytes) : null,
                  child: imageBytes.isEmpty
                      ? const Icon(Icons.person, color: KColors.dark)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Perpustakaan Kejaksaan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Selamat datang, ${widget.nama}",
                        style: const TextStyle(
                          color: KColors.softText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    InkWell(
                      onTap: showNotificationSheet,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: KColors.gold.withOpacity(0.5),
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
                        right: 0,
                        top: 0,
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
            const SizedBox(height: 22),
            KCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              radius: 24,
              borderGold: true,
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: cariBuku,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Cari judul, penulis, atau tahun...",
                  hintStyle: const TextStyle(color: KColors.softText),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: KColors.gold,
                  ),
                  suffixIcon: searchLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KColors.gold,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: KColors.gold,
                          ),
                          onPressed: () => cariBuku(searchController.text),
                        ),
                ),
              ),
            ),
            // ====== FILTER TAHUN DI BAWAH PENCARIAN ======
            const SizedBox(height: 12),
            buildYearFilter(),
            const SizedBox(height: 18),
            SizedBox(
              height: 148,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: bannerController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: banners.length,
                      onPageChanged: (index) {
                        setState(() => currentBanner = index);
                      },
                      itemBuilder: (context, index) {
                        final item = banners[index];
                        return AnimatedBuilder(
                          animation: bannerController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (bannerController.position.haveDimensions) {
                              value = bannerController.page! - index;
                              value =
                                  (1 - (value.abs() * 0.08)).clamp(0.92, 1.0);
                            }
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xff0b3d2e),
                                  Color(0xff0f6b42),
                                ],
                              ),
                              border: Border.all(
                                color: KColors.gold.withOpacity(0.35),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 74,
                                  height: 74,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Image.asset(
                                    "assets/images/logo_kejaksaan.png",
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) {
                                      return const Icon(
                                        Icons.balance_rounded,
                                        color: KColors.gold,
                                        size: 58,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.4,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      banners.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: currentBanner == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: currentBanner == index
                              ? KColors.gold
                              : Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title, {String? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: KText.section),
          ),
          if (action != null)
            Text(
              action,
              style: const TextStyle(
                color: KColors.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Widget dipinjamBadge(int totalDipinjam) {
    if (totalDipinjam <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: KColors.green.withOpacity(0.20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          "Koleksi tersedia",
          style: TextStyle(
            color: KColors.softText,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: KColors.gold.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KColors.gold.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up_rounded, color: KColors.gold, size: 16),
          const SizedBox(width: 5),
          Text(
            "Dipinjam $totalDipinjam kali",
            style: const TextStyle(
              color: KColors.gold,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget rekomendasiCard(Map book) {
    final imageUrl = ApiConfig.fileUrl(book['cover_buku']?.toString());
    final int totalDipinjam =
        int.tryParse((book['total_dipinjam'] ?? 0).toString()) ?? 0;
    return Container(
      width: 188,
      margin: const EdgeInsets.only(right: 16),
      child: KCard(
        padding: EdgeInsets.zero,
        radius: 28,
        borderGold: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 150,
                    color: KColors.card2,
                    child: const Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 55,
                        color: KColors.gold,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['judul'] ?? "-",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book['penulis'] ?? "-",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KColors.softText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    dipinjamBadge(totalDipinjam),
                    const Spacer(),
                    KButton(
                      text: "Pinjam",
                      icon: Icons.menu_book_rounded,
                      loading: bookingLoading,
                      onTap: () => pinjamBuku(book),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rakRow(List<Map<String, dynamic>> racks) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: racks.length,
        itemBuilder: (context, index) {
          final rak = racks[index];
          final namaRak = (rak['nama_rak'] ?? '-').toString();
          final totalBuku =
              int.tryParse((rak['total_buku'] ?? 0).toString()) ?? 0;
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 14),
            child: KStaggeredItem(
              index: index,
              beginOffset: const Offset(0.08, 0),
              child: rakItem(namaRak, rakIcon(namaRak), totalBuku),
            ),
          );
        },
      ),
    );
  }

  Widget rakItem(String namaRak, IconData icon, int totalBuku) {
    return KCard(
      radius: 24,
      borderGold: true,
      onTap: () {
        Navigator.push(
          context,
          KMotion.route(
            BooksByRakPage(
              rak: namaRak,
              userId: widget.userId,
              role: widget.role,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: KGradient.gold,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: KColors.dark, size: 27),
          ),
          const Spacer(),
          Text(
            namaRak,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalBuku > 0 ? "$totalBuku buku" : "Lihat koleksi",
            style: const TextStyle(
              color: KColors.softText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final racks = visibleRacks();
    final topRacks = <Map<String, dynamic>>[];
    final bottomRacks = <Map<String, dynamic>>[];
    for (var i = 0; i < racks.length; i++) {
      (i.isEven ? topRacks : bottomRacks).add(racks[i]);
    }

    return Scaffold(
      backgroundColor: KColors.bg,
      body: RefreshIndicator(
        onRefresh: refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header(),
              const SizedBox(height: 24),
              kartuAnggotaCard(),
              const SizedBox(height: 14),
              requestBukuCard(),
              const SizedBox(height: 24),
              sectionTitle("Buku Populer", action: "Rekomendasi"),
              const SizedBox(height: 16),
              SizedBox(
                height: 345,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : recommendedBooks.isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada rekomendasi",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 18),
                            scrollDirection: Axis.horizontal,
                            itemCount: recommendedBooks.length,
                            itemBuilder: (context, index) {
                              return KStaggeredItem(
                                index: index,
                                beginOffset: const Offset(0.08, 0),
                                child: rekomendasiCard(
                                  Map<String, dynamic>.from(
                                    recommendedBooks[index],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 28),
              sectionTitle("Kategori Rak Buku"),
              const SizedBox(height: 16),
              rakRow(topRacks),
              const SizedBox(height: 14),
              rakRow(bottomRacks),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ),
    );
  }
}