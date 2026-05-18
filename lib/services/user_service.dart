import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class UserService {

  static Future<List> searchUser(String query) async {

    try {

      final res = await http.get(
        Uri.parse("${ApiConfig.users}/search?q=$query"),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return [];
      }

    } catch (e) {

      print("ERROR SEARCH USER: $e");
      return [];

    }

  }

}