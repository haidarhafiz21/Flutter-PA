import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BookService {
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
}