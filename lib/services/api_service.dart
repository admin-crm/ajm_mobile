import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://ajmhrm.cbeezai.com';
  static const String tokenKey = 'api_token';

  late http.Client _client;
  String? _token;

  ApiService() {
    if (kIsWeb) {
      var browserClient = BrowserClient();
      browserClient.withCredentials = true;
      _client = browserClient;
    } else {
      _client = IOClient();
    }
  }

  Future<void> _loadToken() async {
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(tokenKey);
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          _token = data['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(tokenKey, _token!);
          await prefs.setBool('isLoggedIn', true);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _loadToken();
    if (_token != null) {
      try {
        await _client.post(
          Uri.parse('$baseUrl/api/logout'),
          headers: _getHeaders(),
        );
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.setBool('isLoggedIn', false);
    _token = null;
  }

  Future<bool> checkLoginStatus() async {
    await _loadToken();
    if (_token == null) {
      return false;
    }

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/user'),
        headers: _getHeaders(),
      );

      debugPrint('Check login status: ${response.statusCode}');

      final isAuthenticated = response.statusCode == 200;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isAuthenticated);

      if (!isAuthenticated) {
        await prefs.remove(tokenKey);
        _token = null;
      }

      return isAuthenticated;
    } catch (e) {
      debugPrint('Check login error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getLeaveApplications() async {
    await _loadToken();
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/leave-applications'),
        headers: _getHeaders(),
      );

      debugPrint('Leave applications response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['data'] ?? data;
        } catch (e) {
          throw Exception('Failed to parse leave applications JSON');
        }
      } else {
        throw Exception('Failed to load leave applications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load leave applications: $e');
    }
  }

  Future<bool> applyLeave(Map<String, dynamic> leaveData) async {
    await _loadToken();
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/leave-applications'),
        headers: _getHeaders(),
        body: jsonEncode(leaveData),
      );

      debugPrint('Apply leave response: ${response.statusCode} - ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Apply leave error: $e');
      return false;
    }
  }

  Future<bool> cancelLeave(int id) async {
    await _loadToken();
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/leave-applications/$id'),
        headers: _getHeaders(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getLeaveTypes() async {
    await _loadToken();
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/leave-types'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Get leave types error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    await _loadToken();
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/dashboard'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load dashboard data');
    } catch (e) {
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  Future<Map<String, dynamic>> getProfileData() async {
    await _loadToken();
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/profile'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load profile data');
    } catch (e) {
      throw Exception('Failed to load profile data: $e');
    }
  }
}