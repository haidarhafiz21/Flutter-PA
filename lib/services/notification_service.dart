import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NotificationService {
  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map && data["data"] is List) {
      return data["data"];
    }

    return [];
  }

  static bool _isAdminNotification(dynamic item) {
    if (item is! Map) return false;

    final tipe = (item["tipe_notifikasi"] ??
            item["tipe"] ??
            item["type"] ??
            item["title"] ??
            item["judul"] ??
            "")
        .toString()
        .toUpperCase();

    return tipe.startsWith("ADMIN_") || tipe.contains("NOTIFIKASI ADMIN");
  }

  static bool _belongsToUser(dynamic item, int userId) {
    if (item is! Map) return false;

    final itemUserId = int.tryParse("${item["user_id"] ?? userId}") ?? userId;
    return itemUserId == userId;
  }

  static Future<List<dynamic>> getUserNotifications(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/notifications/user/$userId"),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : [];
      return _extractList(data)
          .where((item) => _belongsToUser(item, userId))
          .where((item) => !_isAdminNotification(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAdminNotifications(int adminId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.adminNotifications}?user_id=$adminId"),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : [];
      return _extractList(data)
          .where((item) => _isAdminNotification(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<int> getUnreadCount(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/notifications/user/$userId/unread-count"),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      return int.tryParse("${data["count"] ?? 0}") ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> markAsRead(int id) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/notifications/read/$id"),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      return data["success"] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> markAllAsRead(int userId) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/notifications/read-all/$userId"),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      return data["success"] == true;
    } catch (e) {
      return false;
    }
  }
}
