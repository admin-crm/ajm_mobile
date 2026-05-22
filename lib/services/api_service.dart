import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Adjust this baseUrl depending on deployment
  // Since it's a web app hosted on the same domain, relative path or full domain works.
  // During local development, assume Laravel is running on port 8000.
  static const String baseUrl = 'https://ajmhrm.cbeezai.com/';
   
  late http.Client _client;

  ApiService() {
    if (kIsWeb) {
      // In web, we need BrowserClient to send cookies automatically with credentials
      var browserClient = BrowserClient();
      browserClient.withCredentials = true;
      _client = browserClient;
    } else {
      // For mobile, we need to handle cookies manually or use a cookie-aware client
      _client = IOClient();
    }
  }

  Future<void> initCsrf() async {
    final response = await _client.get(Uri.parse('$baseUrl/sanctum/csrf-cookie'));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to initialize CSRF token');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      await initCsrf();
      final response = await _client.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          // Note: X-CSRF-TOKEN header is not needed if we're using cookies properly
          // The Sanctum CSRF cookie will be sent automatically with our cookie-aware client
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Login successful, session cookie is stored by browser/client
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // If CSRF fails, try without it (some configurations might not require it)
      try {
        final response = await _client.post(
          Uri.parse('$baseUrl/login'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          return true;
        } else {
          return false;
        }
      } catch (e) {
        return false;
      }
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      // Ignore logout errors
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
  }

  Future<bool> checkLoginStatus() async {
    // Actually check with the server instead of just local storage
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/user'), // Assuming you have an API endpoint to get current user
        headers: {
          'Accept': 'application/json',
        },
      );
      
      final isAuthenticated = response.statusCode == 200;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isAuthenticated);
      return isAuthenticated;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      return false;
    }
  }

  // --- Leave Management APIs ---
  // Using the hr/leave-applications web routes as API endpoints if they respond to JSON.
  // We'll need to adapt this depending on what the Laravel controller actually returns.

  Future<List<dynamic>> getLeaveApplications() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/hr/leave-applications'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // We assume the backend returns JSON when 'Accept: application/json' is sent.
          // If the backend returns HTML, this will fail and we'd need a dedicated API route.
          return data['data'] ?? data;
        } catch (e) {
          throw Exception('Failed to parse leave applications JSON. Ensure backend returns JSON.');
        }
      } else {
        throw Exception('Failed to load leave applications');
      }
    } catch (e) {
      throw Exception('Failed to load leave applications: $e');
    }
  }

  Future<bool> applyLeave(Map<String, dynamic> leaveData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/hr/leave-applications'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(leaveData),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelLeave(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/hr/leave-applications/$id'),
        headers: {
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}