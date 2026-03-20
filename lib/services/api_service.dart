import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://alivecheck.app/api";

  // ================= LOGIN =================
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "email": email,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
    }

    return null;
  }

  // ================= HEADERS =================
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      throw Exception("NO TOKEN");
    }

    return {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
      "Content-Type": "application/json",
    };
  }

  // ================= USER =================
  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/me"),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print("USER STATUS: ${response.statusCode}");
      print("USER BODY: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("USER ERROR: $e");
    }

    return null;
  }

  // ================= STATUS =================
  static Future<Map<String, dynamic>?> getStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/status"),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print("STATUS API: ${response.statusCode}");
      print("STATUS BODY: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("STATUS ERROR: $e");
    }

    return null;
  }

  // ================= CHECK-IN =================
  static Future<bool> checkIn() async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/checkin"),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print("CHECKIN STATUS: ${response.statusCode}");
      print("CHECKIN BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("CHECKIN ERROR: $e");
      return false;
    }
  }
}