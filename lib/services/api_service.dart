import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/downloader.dart';
import '../utils/client_stub.dart'
    if (dart.library.html) '../utils/client_web.dart'
    if (dart.library.io) '../utils/client_mobile.dart';

class ApiService {
  static const String baseUrl = 'https://hrm.cbeezai.com';
  //  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String tokenKey = 'api_token';

  late http.Client _client;
  String? _token;

  ApiService() {
    _client = getClient();
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

  Future<List<dynamic>> getLeaveApplications({String? startDate, String? endDate}) async {
    await _loadToken();
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final baseUri = Uri.parse('$baseUrl/api/leave-applications');
      final uri = queryParams.isNotEmpty ? baseUri.replace(queryParameters: queryParams) : baseUri;

      final response = await _client.get(
        uri,
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

  Future<List<dynamic>> getShortPermissions({String? startDate, String? endDate}) async {
    await _loadToken();
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final baseUri = Uri.parse('$baseUrl/api/short-permissions');
      final uri = queryParams.isNotEmpty ? baseUri.replace(queryParameters: queryParams) : baseUri;

      final response = await _client.get(
        uri,
        headers: _getHeaders(),
      );

      debugPrint('Short permissions response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['data'] ?? data;
        } catch (e) {
          throw Exception('Failed to parse short permissions JSON');
        }
      } else {
        throw Exception('Failed to load short permissions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load short permissions: $e');
    }
  }

  Future<List<dynamic>> getAttendanceRecords({String? startDate, String? endDate, String? status}) async {
    await _loadToken();
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (status != null) queryParams['status'] = status;

      final baseUri = Uri.parse('$baseUrl/api/attendance-records');
      final uri = queryParams.isNotEmpty ? baseUri.replace(queryParameters: queryParams) : baseUri;

      final response = await _client.get(
        uri,
        headers: _getHeaders(),
      );

      debugPrint('Attendance records response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['data'] ?? data;
        } catch (e) {
          throw Exception('Failed to parse attendance records JSON');
        }
      } else {
        throw Exception('Failed to load attendance records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load attendance records: $e');
    }
  }

  Future<bool> applyShortPermission(Map<String, dynamic> permissionData) async {
    await _loadToken();
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/short-permissions'),
        headers: _getHeaders(),
        body: jsonEncode(permissionData),
      );

      debugPrint('Apply short permission response: ${response.statusCode} - ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Apply short permission error: $e');
      return false;
    }
  }

  Future<bool> cancelShortPermission(int id) async {
    await _loadToken();
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/short-permissions/$id'),
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

  Future<List<dynamic>> getPayslips() async {
    await _loadToken();
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/payslips'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      throw Exception('Failed to load payslips: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load payslips: $e');
    }
  }

  Future<void> downloadPayslip(int id, String payslipNumber) async {
    await _loadToken();
    final url = '$baseUrl/api/payslips/$id/download';
    final filename = 'payslip-$payslipNumber.pdf';
    final headers = _getHeaders();
    await FileDownloader.downloadFile(url, filename, headers);
  }
}