class ApiConfig {
  static const String baseUrl = "http://192.168.1.2:3000/api";
  static const String baseFileUrl = "http://192.168.1.2:3000";

  // ================= AUTH =================
  static const String register = "$baseUrl/auth/register";
  static const String login = "$baseUrl/auth/login";

  // ================= USERS =================
  static const String users = "$baseUrl/users";
  static const String members = "$baseUrl/users/members";
  static const String verifyFace = "$baseUrl/users/verify-face";
  static const String updateFace = "$baseUrl/users/update-face";
  static const String profile = "$baseUrl/users/profile";
  static const String searchUser = "$baseUrl/users/search";

  // ================= BOOKS =================
  static const String books = "$baseUrl/books";
  static const String recommendedBooks = "$baseUrl/books/recommended";
  static const String booksByRack = "$baseUrl/books/by-rak";
  static const String digitalBooks = "$baseUrl/books/digital";
  static const String readBook = "$baseUrl/books/read";

  // ================= BORROWS =================
  static const String booking = "$baseUrl/borrows/booking";
  static const String scanBorrow = "$baseUrl/borrows/scan";
  static const String returnBook = "$baseUrl/borrows/return";
  static const String activeBorrows = "$baseUrl/borrows/active";
  static const String userBorrows = "$baseUrl/borrows/user-borrows";
  static const String allBorrows = "$baseUrl/borrows/all";
  static const String cekTerlambat = "$baseUrl/borrows/cek-terlambat";
  static const String cancelExpired = "$baseUrl/borrows/cancel-expired";
  static const String userBooking = "$baseUrl/borrows/user-booking";

  // ================= ADMIN BORROW LIST =================
  static const String bookingList = "$baseUrl/borrows/booking-list";
  static const String activeList = "$baseUrl/borrows/active-list";
  static const String returnList = "$baseUrl/borrows/return-list";
  static const String lateList = "$baseUrl/borrows/late-list";
  static const String dendaList = "$baseUrl/borrows/denda-list";
  static const String historyPembayaran = "$baseUrl/borrows/history-pembayaran";
  static const String historyPengembalian = "$baseUrl/borrows/history-pengembalian";
  static const String bayarOffline = "$baseUrl/borrows/bayar-offline";
  static const String bayarOnline = "$baseUrl/borrows/bayar-online";
  static const String manualDenda = "$baseUrl/borrows/manual-denda";

  // ================= PAYMENT =================
  static const String createDendaPayment = "$baseUrl/payment/create-denda";
  static const String syncPaymentStatus = "$baseUrl/payment/sync-status";

  // ================= FILE URL =================
  static String fileUrl(String? path) {
    if (path == null || path.isEmpty) return "";

    if (path.startsWith("http://") || path.startsWith("https://")) {
      return path;
    }

    if (path.startsWith("/")) {
      return "$baseFileUrl$path";
    }

    return "$baseFileUrl/$path";
  }
}