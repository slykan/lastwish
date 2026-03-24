import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class ApiService {
        // ================= FCM TOKEN =================
        static Future<void> saveFcmToken(String token) async {
          try {
            await http.post(
              Uri.parse("$baseUrl/fcm-token"),
              headers: await getHeaders(),
              body: jsonEncode({'fcm_token': token}),
            ).timeout(const Duration(seconds: 10));
          } catch (e) {
            print("FCM TOKEN ERROR: $e");
          }
        }

        // ================= PEOPLE I PROTECT =================
        static Future<List<dynamic>> fetchProtectedPeople() async {
          try {
            final response = await http.get(
              Uri.parse("$baseUrl/guardian/protected-status"),
              headers: await getHeaders(),
            ).timeout(const Duration(seconds: 10));
            print("PROTECTED PEOPLE STATUS: "+response.statusCode.toString());
            print("PROTECTED PEOPLE BODY: "+response.body);
            if (response.statusCode == 200) {
              return jsonDecode(response.body) as List<dynamic>;
            }
          } catch (e) {
            print("PROTECTED PEOPLE ERROR: $e");
          }
          return [];
        }
      // ================= INVITES =================
      static Future<Map<String, dynamic>> sendInvite(String email, String role) async {
        try {
          final response = await http.post(
            Uri.parse("$baseUrl/invite"),
            headers: await getHeaders(),
            body: jsonEncode({'email': email, 'role': role}),
          ).timeout(const Duration(seconds: 10));
          print("SEND INVITE STATUS: ${response.statusCode}");
          print("SEND INVITE BODY: ${response.body}");
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return {'success': true};
          }
          final body = jsonDecode(response.body);
          return {'success': false, 'message': body['message'] ?? 'Error sending invite'};
        } catch (e) {
          print("SEND INVITE ERROR: $e");
          return {'success': false, 'message': 'Connection error'};
        }
      }

      static Future<List<dynamic>> fetchSentInvites() async {
        try {
          final response = await http.get(
            Uri.parse("$baseUrl/invites/sent"),
            headers: await getHeaders(),
          ).timeout(const Duration(seconds: 10));
          print("SENT INVITES STATUS: ${response.statusCode}");
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded is List) return decoded;
            if (decoded is Map && decoded['invites'] is List) return decoded['invites'] as List<dynamic>;
            if (decoded is Map && decoded['data'] is List) return decoded['data'] as List<dynamic>;
          }
          // 404 = endpoint not yet added to backend, return empty silently
        } catch (e) {
          print("SENT INVITES ERROR: $e");
        }
        return [];
      }

      static Future<List<dynamic>> fetchInvites() async {
        try {
          final response = await http.get(
            Uri.parse("$baseUrl/invites"),
            headers: await getHeaders(),
          ).timeout(const Duration(seconds: 10));
          print("INVITES STATUS: ${response.statusCode}");
          print("INVITES BODY: ${response.body}");
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded is List) return decoded;
            if (decoded is Map && decoded['data'] != null) return decoded['data'] as List<dynamic>;
            return [];
          }
        } catch (e) {
          print("INVITES ERROR: $e");
        }
        return [];
      }

      static Future<bool> acceptInvite(int id) async {
        try {
          final response = await http.post(
            Uri.parse("$baseUrl/invite/$id/accept"),
            headers: await getHeaders(),
          ).timeout(const Duration(seconds: 10));
          return response.statusCode == 200;
        } catch (e) {
          print("ACCEPT INVITE ERROR: $e");
          return false;
        }
      }

      static Future<bool> declineInvite(int id) async {
        try {
          final response = await http.post(
            Uri.parse("$baseUrl/invite/$id/decline"),
            headers: await getHeaders(),
          ).timeout(const Duration(seconds: 10));
          return response.statusCode == 200;
        } catch (e) {
          print("DECLINE INVITE ERROR: $e");
          return false;
        }
      }
    // ================= GUARDIANS (those who protect me) =================
    static Future<List<dynamic>> fetchGuardians() async {
      try {
        final response = await http.get(
          Uri.parse("$baseUrl/protected/guardians"),
          headers: await getHeaders(),
        ).timeout(const Duration(seconds: 10));

        print("GUARDIANS STATUS: "+response.statusCode.toString());
        print("GUARDIANS BODY: "+response.body);

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as List<dynamic>;
        }
      } catch (e) {
        print("GUARDIANS ERROR: $e");
      }
      return [];
    }

    static Future<bool> removeGuardian(int relationshipId) async {
      try {
        final response = await http.post(
          Uri.parse("$baseUrl/protected/relationship/$relationshipId/remove"),
          headers: await getHeaders(),
        ).timeout(const Duration(seconds: 10));
        print("REMOVE GUARDIAN STATUS: ${response.statusCode}");
        return response.statusCode >= 200 && response.statusCode < 300;
      } catch (e) {
        print("REMOVE GUARDIAN ERROR: $e");
        return false;
      }
    }
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

  static Future<Map<String, dynamic>?> register(
      String name, String email, String password, {
      String? phone,
      String? bloodType,
      String? allergies,
      String? medications,
      String? emergencyNote,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (phone != null) 'phone': phone,
        if (bloodType != null) 'blood_type': bloodType,
        if (allergies != null) 'allergies': allergies,
        if (medications != null) 'medications': medications,
        if (emergencyNote != null) 'emergency_note': emergencyNote,
      };
      final response = await http
          .post(
            Uri.parse("$baseUrl/register"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.body}");

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return decoded;
      }
      return {'message': decoded['message'] ?? 'Registration failed.'};
    } catch (e) {
      print("REGISTER ERROR: $e");
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

  // ================= PROFILE =================
  static Future<Map<String, dynamic>?> fetchMe() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/me"),
        headers: await getHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { print("FETCH ME ERROR: $e"); }
    return null;
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
    String? bloodType,
    String? allergies,
    String? medications,
    String? emergencyNote,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (phone != null) 'phone': phone,
        if (bloodType != null) 'blood_type': bloodType,
        if (allergies != null) 'allergies': allergies,
        if (medications != null) 'medications': medications,
        if (emergencyNote != null) 'emergency_note': emergencyNote,
      };
      final response = await http.put(
        Uri.parse("$baseUrl/profile"),
        headers: await getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      print("UPDATE PROFILE STATUS: ${response.statusCode}");
      print("UPDATE PROFILE BODY: ${response.body}");
      if (response.statusCode == 200) return {'success': true};
      final decoded = jsonDecode(response.body);
      return {'success': false, 'message': decoded['message'] ?? 'Update failed.'};
    } catch (e) {
      print("UPDATE PROFILE ERROR: $e");
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  static Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/profile/password"),
        headers: await getHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));
      print("UPDATE PASSWORD STATUS: ${response.statusCode}");
      if (response.statusCode == 200) return {'success': true};
      final decoded = jsonDecode(response.body);
      return {'success': false, 'message': decoded['message'] ?? 'Failed to update password.'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/profile"),
        headers: await getHeaders(),
      ).timeout(const Duration(seconds: 10));
      print("DELETE ACCOUNT STATUS: ${response.statusCode}");
      if (response.statusCode == 200) return {'success': true};
      final decoded = jsonDecode(response.body);
      return {'success': false, 'message': decoded['message'] ?? 'Failed to delete account.'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
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

  // ================= SETTINGS =================
  static Future<Map<String, dynamic>?> fetchSettings() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/settings"),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['settings'] ?? decoded;
      }
    } catch (e) {
      print("FETCH SETTINGS ERROR: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>> saveSettings({
    required int aliveIntervalHours,
    required int graceHours,
    required int reminderBeforeHours,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse("$baseUrl/settings"),
            headers: await getHeaders(),
            body: jsonEncode({
              'alive_interval_hours': aliveIntervalHours,
              'grace_hours': graceHours,
              'reminder_hours_before': reminderBeforeHours,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, ...decoded};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Server error'};
    } catch (e) {
      print("SAVE SETTINGS ERROR: $e");
      return {'success': false, 'message': e.toString()};
    }
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
      // Pokušaj dohvatiti lokaciju
      Map<String, dynamic> body = {};
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
          body = {'latitude': pos.latitude, 'longitude': pos.longitude};
          print("CHECKIN LOCATION: ${pos.latitude}, ${pos.longitude}");
        }
      } catch (locErr) {
        print("CHECKIN LOCATION ERROR: $locErr");
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/checkin"),
            headers: await getHeaders(),
            body: body.isNotEmpty ? jsonEncode(body) : null,
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

  // ================= REMIND PROTECTED =================
  static Future<bool> remindProtected(int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/guardian/remind/$userId"),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print("REMIND STATUS: ${response.statusCode}");
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("REMIND ERROR: $e");
      return false;
    }
  }

  // ================= GUARDIAN ACTIVITY FEED =================
  static Future<List<dynamic>> fetchActivityFeed() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/guardian/activity-feed"),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print("ACTIVITY FEED STATUS: ${response.statusCode}");
      print("ACTIVITY FEED BODY: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print("ACTIVITY FEED ERROR: $e");
    }
    return [];
  }

  // ================= CHECKIN HISTORY =================
  static Future<List<dynamic>> fetchCheckinHistory(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/guardian/checkins/$userId"),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("CHECKIN HISTORY RAW: $decoded");
        if (decoded is List) return decoded;
        if (decoded is Map) {
          if (decoded['history'] is List) return decoded['history'] as List<dynamic>;
          if (decoded['data'] is List) return decoded['data'] as List<dynamic>;
          if (decoded['checkins'] is List) return decoded['checkins'] as List<dynamic>;
        }
      }
    } catch (e) {
      print("CHECKIN HISTORY ERROR: $e");
    }
    return [];
  }
}