import 'dart:convert';
import 'package:http/http.dart' as http;

import '../home/models/dashboard_models.dart';

const String apiBaseUrl = 'https://ticket.pepa.mn';

enum UserRole { admin, organizer }

class CheckQrResponse {
  final String alertType;
  final String message;
  final String? bookingId;

  const CheckQrResponse({
    required this.alertType,
    required this.message,
    this.bookingId,
  });

  bool get isSuccess => alertType.toLowerCase() == 'success';

  factory CheckQrResponse.fromJson(Map<String, dynamic> json) {
    return CheckQrResponse(
      alertType: (json['alert_type'] ?? json['type'] ?? 'error').toString(),
      message: (json['message'] ?? '').toString(),
      bookingId: json['booking_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'alert_type': alertType,
    'message': message,
    if (bookingId != null) 'booking_id': bookingId,
  };
}

class UserProfile {
  final UserRole role;
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? photoUrl;

  UserProfile({
    required this.role,
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'id': id,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final role = json['role'] == 'admin' ? UserRole.admin : UserRole.organizer;
    return UserProfile(
      role: role,
      id: (json['id'] as num).toInt(),
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      photoUrl: json['photoUrl'],
    );
  }

  String get displayName {
    if (role == UserRole.admin) {
      final hasNames =
          (firstName?.isNotEmpty == true) || (lastName?.isNotEmpty == true);
      return hasNames
          ? [
              firstName,
              lastName,
            ].whereType<String>().where((e) => e.isNotEmpty).join(' ')
          : username;
    } else {
      return username.toUpperCase();
    }
  }
}

class LoginSuccess {
  final String token;
  final UserProfile profile;
  LoginSuccess(this.token, this.profile);
}

class ApiClient {
  final http.Client _client;
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _buildUri(String path, Map<String, String> query) {
    final base = apiBaseUrl.replaceAll(RegExp(r"/+$"), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<LoginSuccess> loginUnified({
    required String username,
    required String password,
    required String deviceName,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/');

    print('🔵 LOGIN REQUEST:');
    print('   URL: $uri');
    print('   User: $username');
    print(
      '   Body: ${json.encode({'op': 'login', 'user': username, 'pass': '***'})}',
    );

    final resp = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'op': 'login', 'user': username, 'pass': password}),
    );

    print('🟢 LOGIN RESPONSE:');
    print('   Status: ${resp.statusCode}');
    print('   Body: ${resp.body}');

    if (resp.statusCode != 200) {
      print('❌ Login failed with status ${resp.statusCode}');
      throw Exception('Login failed: ${resp.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(resp.body);

    // Check if login was successful
    if (data['ok'] != true) {
      print('❌ Login failed: ok=${data['ok']}');
      throw Exception('Invalid credentials');
    }

    final responseData = data['data'] as Map<String, dynamic>;
    final token = responseData['token']?.toString();
    final user = responseData['user']?.toString();

    print('🟡 PARSED DATA:');
    print('   Token: ${token?.substring(0, 20)}...');
    print('   User: $user');

    if (token == null || token.isEmpty) {
      print('❌ No token received');
      throw Exception('No token received');
    }

    // Create a basic user profile (no admin/organizer distinction for now)
    final profile = UserProfile(
      role: UserRole.admin, // Default role
      id: 0, // No ID in response
      username: user ?? username,
      firstName: null,
      lastName: null,
      email: null,
      phone: null,
      photoUrl: null,
    );

    print('✅ LOGIN SUCCESS:');
    print('   Username: ${profile.username}');
    print('   Role: ${profile.role.name}');

    return LoginSuccess(token, profile);
  }

  /// Check a scanned QR code against the backend.
  ///
  /// Sends POST form fields `{ booking_id: ... }` to either the admin or
  /// organizer endpoint based on the provided [role]. Returns the server's
  /// JSON payload mapped into [CheckQrResponse].
  Future<CheckQrResponse> checkQrCode({
    required String token,
    required UserRole role,
    required String bookingId,
  }) async {
    if (apiBaseUrl.contains('YOUR_API_BASE_URL_HERE')) {
      throw Exception('Please set apiBaseUrl in lib/services/api_client.dart');
    }

    final path = role == UserRole.admin
        ? '/api/scanner/admin/check-qrcode'
        : '/api/scanner/organizer/check-qrcode';
    final uri = _buildUri(path, const {});

    final resp = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        // If your backend expects a different token header, adjust here.
        'Authorization': 'Bearer $token',
      },
      body: {'booking_id': bookingId},
    );

    // Parse gracefully even on non-200s if server returns JSON
    Map<String, dynamic>? jsonBody;
    try {
      jsonBody = json.decode(resp.body) as Map<String, dynamic>;
    } catch (_) {}

    if (jsonBody != null && jsonBody.isNotEmpty) {
      return CheckQrResponse.fromJson(jsonBody);
    }

    // Fallback generic errors
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return const CheckQrResponse(alertType: 'success', message: 'Verified');
    }
    return CheckQrResponse(
      alertType: 'error',
      message: 'Verification failed (${resp.statusCode})',
    );
  }

  /// Fetch dashboard data including events, tickets, and statistics.
  ///
  /// Returns dashboard data with events list, scanned/unscanned tickets,
  /// and various statistics for the authenticated user.
  Future<DashboardData> getDashboardData({
    required String token,
    required UserRole role,
  }) async {
    if (apiBaseUrl.contains('YOUR_API_BASE_URL_HERE')) {
      throw Exception('Please set apiBaseUrl in lib/services/api_client.dart');
    }

    final path = role == UserRole.admin
        ? '/api/scanner/admin/events'
        : '/api/scanner/organizer/events';
    final uri = _buildUri(path, const {});

    final resp = await _client.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      // Log full error for debugging
      throw Exception(
        'Failed to load dashboard data: ${resp.statusCode} - ${resp.body}',
      );
    }

    final Map<String, dynamic> data = json.decode(resp.body);

    if (data['status']?.toString().toLowerCase() != 'success') {
      throw Exception('Dashboard data fetch failed');
    }

    return DashboardData.fromJson(data);
  }

  /// Update ticket scan status.
  ///
  /// Changes the scan status of a ticket (scanned/unscanned).
  Future<bool> updateTicketStatus({
    required String token,
    required UserRole role,
    required String bookingId,
    required String ticketId,
    required String status,
  }) async {
    if (apiBaseUrl.contains('YOUR_API_BASE_URL_HERE')) {
      throw Exception('Please set apiBaseUrl in lib/services/api_client.dart');
    }

    final path = role == UserRole.admin
        ? '/api/scanner/admin/ticket/scanned-status-change'
        : '/api/scanner/organizer/ticket/scanned-status-change';
    final uri = _buildUri(path, {
      'booking_id': bookingId,
      'ticket_id': ticketId,
      'status': status,
    });

    final resp = await _client.post(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to update ticket status: ${resp.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(resp.body);
    final success = data['status']?.toString().toLowerCase() == 'success';
    return success;
  }
}
