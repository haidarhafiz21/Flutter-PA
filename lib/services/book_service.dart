import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BookService {
  static const String digitalRackName = "Buku Online";
  static const List<String> digitalRackAliases = ["Buku Online", "Buku PDF"];

  static bool isDigitalRack(String rak) {
    final normalized = rak.trim().toLowerCase();
    return digitalRackAliases.any(
      (item) => item.toLowerCase() == normalized,
    );
  }

  static Future<List> getDigitalBooks() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.digitalBooks))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        return data is List ? data : [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List> getRecommended(String role) async {
    try {
      final res = await http
          .get(Uri.parse("${ApiConfig.recommendedBooks}?role=$role"))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        return data is List ? data : [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List> getBooksByRack(String rak, String role) async {
    if (isDigitalRack(rak)) {
      return getDigitalBooks();
    }

    try {
      final uri = Uri.parse(ApiConfig.booksByRack).replace(
        queryParameters: {
          "rak": rak,
          "role": role,
        },
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        return data is List ? data : [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List> getAllRacks() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.allRacks))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        return data is List ? data : [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
