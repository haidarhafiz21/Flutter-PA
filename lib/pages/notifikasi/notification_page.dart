import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../widgets/kejaksaan_ui.dart';

class NotificationPage extends StatefulWidget {
  final int userId;

  const NotificationPage({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() => loading = true);

    final result = await NotificationService.getUserNotifications(widget.userId);

    if (!mounted) return;

    setState(() {
      notifications = result;
      loading = false;
    });
  }

  Future<void> readOne(Map notif) async {
    final id = int.tryParse("${notif["id"]}") ?? 0;
    if (id == 0) return;

    await NotificationService.markAsRead(id);
    await loadNotifications();
  }

  Future<void> readAll() async {
    await NotificationService.markAllAsRead(widget.userId);
    await loadNotifications();
  }

  String title(Map notif) {
    return (notif["title"] ?? notif["judul"] ?? "Notifikasi").toString();
  }

  String message(Map notif) {
    return (notif["message"] ?? notif["pesan"] ?? "-").toString();
  }

  String date(Map notif) {
    final raw = (notif["created_at"] ?? "").toString();

    if (raw.isEmpty) return "-";

    try {
      final dt = DateTime.parse(raw).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return raw;
    }
  }

  IconData icon(Map notif) {
    final text = "${title(notif)} ${message(notif)}".toLowerCase();

    if (text.contains("terlambat")) return Icons.warning_rounded;
    if (text.contains("h-2")) return Icons.access_time_filled_rounded;
    if (text.contains("h-1")) return Icons.notifications_active_rounded;
    if (text.contains("hari ini")) return Icons.today_rounded;
    if (text.contains("denda") || text.contains("pembayaran")) {
      return Icons.payments_rounded;
    }

    return Icons.notifications_rounded;
  }

  Widget itemCard(Map notif) {
    final isRead = notif["is_read"] == true;

    return KCard(
      borderGold: !isRead,
      radius: 24,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      onTap: () => readOne(notif),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isRead ? null : KGradient.gold,
              color: isRead ? KColors.card2 : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isRead
                    ? Colors.white.withOpacity(0.08)
                    : KColors.gold.withOpacity(0.6),
              ),
            ),
            child: Icon(
              isRead ? Icons.done_all_rounded : icon(notif),
              color: isRead ? KColors.softText : KColors.dark,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title(notif),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isRead ? KColors.softText : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: KColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  message(notif),
                  style: TextStyle(
                    color: isRead ? KColors.softText.withOpacity(0.7) : KColors.softText,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text(
                      date(notif),
                      style: const TextStyle(
                        color: KColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isRead ? "Sudah dibaca" : "Belum dibaca",
                      style: TextStyle(
                        color: isRead ? KColors.softText : KColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return const Center(
      child: Text(
        "Belum ada notifikasi.",
        style: TextStyle(
          color: KColors.softText,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((e) {
      final n = Map<String, dynamic>.from(e);
      return n["is_read"] != true;
    }).length;

    return Scaffold(
      backgroundColor: KColors.bg,
      body: Column(
        children: [
          KHeader(
            title: "Notifikasi",
            subtitle: "$unread belum dibaca",
            trailing: IconButton(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          if (notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: unread > 0 ? readAll : null,
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
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: KColors.gold),
                  )
                : notifications.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 6, bottom: 24),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            return itemCard(
                              Map<String, dynamic>.from(notifications[index]),
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