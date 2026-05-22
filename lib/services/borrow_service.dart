import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BorrowService {
  /// ================= REGISTER =================
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String alamat,
    required String email,
    required String password,
    required String foto,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "nama": nama,
          "alamat": alamat,
          "email": email,
          "password": password,
          "foto": foto,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Koneksi ke server gagal"};
    }
  }

  /// ================= LOGIN =================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Koneksi ke server gagal"};
    }
  }

  /// ================= UPDATE FOTO WAJAH =================
  static Future<Map<String, dynamic>> updateFace({
    required int userId,
    required String fotoWajah,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.updateFace),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "foto_wajah": fotoWajah,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Gagal update foto wajah"};
    }
  }

  /// ================= BOOKING =================
  static Future<Map<String, dynamic>> booking({
    required int userId,
    required int bookId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.booking),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "book_id": bookId,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Booking gagal"};
    }
  }

  /// ================= SCAN ADMIN =================
  static Future<Map<String, dynamic>> scanBorrow({
    required int userId,
    required int bookId,
    int? adminId,
    String fotoScan = "",
    String fotoLive = "",
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.scanBorrow),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "book_id": bookId,
          if (adminId != null) "admin_id": adminId,
          "foto_scan": fotoScan,
          "foto_liveness": fotoLive,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Scan buku gagal"};
    }
  }

  /// ================= RETURN =================
  static Future<Map<String, dynamic>> returnBook({
    required int bookId,
    int? peminjamanId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.returnBook),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "book_id": bookId,
          if (peminjamanId != null) "peminjaman_id": peminjamanId,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Return gagal"};
    }
  }

  /// ================= STATUS AKTIF USER =================
  static Future<List<dynamic>> getActiveBorrow(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.activeBorrows}?user_id=$userId"),
      );

      if (res.body == "null" || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;
      if (data is Map<String, dynamic>) return [data];

      return [];
    } catch (e) {
      return [];
    }
  }

  /// ================= RIWAYAT USER =================
  static Future<List<dynamic>> getUserBorrows(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.userBorrows}/$userId"),
      );

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;
      if (data is Map<String, dynamic>) return [data];

      return [];
    } catch (e) {
      return [];
    }
  }

  /// ================= USER BOOKING =================
  static Future<List<dynamic>> getUserBooking(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.userBooking}/$userId"),
      );

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;
      if (data is Map<String, dynamic>) return [data];

      return [];
    } catch (e) {
      return [];
    }
  }

  /// ================= ADMIN ALL BORROWS =================
  static Future<List<dynamic>> getAllBorrows() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.allBorrows),
      );

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;
      if (data is Map<String, dynamic>) return [data];

      return [];
    } catch (e) {
      return [];
    }
  }

  /// ================= MEMBERS =================
  static Future<List<dynamic>> getMembers() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.members),
      );

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;
      if (data is Map<String, dynamic>) return [data];

      return [];
    } catch (e) {
      return [];
    }
  }

  /// ================= LIST BOOKING ADMIN =================
  static Future<List<dynamic>> getBookingList() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.bookingList));

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);
      return data is List ? data : [];
    } catch (e) {
      return [];
    }
  }

  /// ================= LIST AKTIF ADMIN =================
  static Future<List<dynamic>> getActiveList() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.activeList));

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);
      return data is List ? data : [];
    } catch (e) {
      return [];
    }
  }

  /// ================= LIST PENGEMBALIAN ADMIN =================
  static Future<List<dynamic>> getReturnList() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.returnList));

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);
      return data is List ? data : [];
    } catch (e) {
      return [];
    }
  }

  /// ================= LIST TERLAMBAT ADMIN =================
  static Future<List<dynamic>> getLateList() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.lateList));

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);
      return data is List ? data : [];
    } catch (e) {
      return [];
    }
  }

  /// ================= LIST DENDA =================
  static Future<List<dynamic>> getDendaList() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.dendaList));

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);
      return data is List ? data : [];
    } catch (e) {
      return [];
    }
  }

  /// ================= HISTORY PEMBAYARAN =================
  static Future<List<dynamic>> getHistoryPembayaran() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.historyPembayaran));

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);
      return data is List ? data : [];
    } catch (e) {
      return [];
    }
  }

  /// ================= HISTORY PENGEMBALIAN =================
  static Future<List<dynamic>> getHistoryPengembalian() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.historyPengembalian));

      if (res.statusCode != 200 || res.body.isEmpty) return [];

      final data = jsonDecode(res.body);
      return data is List ? data : [];
    } catch (e) {
      return [];
    }
  }

  /// ================= INPUT DENDA MANUAL =================
  static Future<Map<String, dynamic>> inputManualDenda({
    required int peminjamanId,
    int dendaKerusakan = 0,
    int dendaKehilangan = 0,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.manualDenda),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "peminjaman_id": peminjamanId,
          "denda_kerusakan": dendaKerusakan,
          "denda_kehilangan": dendaKehilangan,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Gagal input denda"};
    }
  }

  /// ================= BAYAR OFFLINE =================
  static Future<Map<String, dynamic>> bayarOffline({
    required int peminjamanId,
    required int jumlah,
    int? adminId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.bayarOffline),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "peminjaman_id": peminjamanId,
          "jumlah": jumlah,
          if (adminId != null) "admin_id": adminId,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Pembayaran cash gagal"};
    }
  }

  /// ================= BAYAR ONLINE DARI ADMIN =================
  static Future<Map<String, dynamic>> bayarOnline({
    required int peminjamanId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.bayarOnline),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "peminjaman_id": peminjamanId,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Gagal membuat tagihan online"};
    }
  }

  /// ================= BUAT TAGIHAN ONLINE MIDTRANS =================
  static Future<Map<String, dynamic>> createDendaPayment(int peminjamanId) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.createDendaPayment),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "peminjaman_id": peminjamanId,
        }),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Gagal membuat tagihan online"};
    }
  }

  /// ================= SYNC STATUS PEMBAYARAN =================
  static Future<Map<String, dynamic>> syncPaymentStatus(int peminjamanId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.syncPaymentStatus}/$peminjamanId"),
      );

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Gagal sinkron status pembayaran"};
    }
  }

  /// ================= CEK TERLAMBAT =================
  static Future<Map<String, dynamic>> cekTerlambat() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.cekTerlambat));

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Gagal update terlambat"};
    }
  }

  /// ================= CANCEL BOOKING EXPIRED =================
  static Future<Map<String, dynamic>> cancelExpiredBooking() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.cancelExpired));

      return res.body.isNotEmpty
          ? jsonDecode(res.body)
          : {"success": false, "message": "Response kosong"};
    } catch (e) {
      return {"success": false, "message": "Gagal membatalkan booking expired"};
    }
  }
}
