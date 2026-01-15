import 'dart:convert';
import 'package:http/http.dart' as http;

import '../home/models/dashboard_models.dart';

const String apiBaseUrl = 'https://ticket.pepa.mn';

enum UserRole { admin, organizer }

class CheckQrResponse {
  final String alertType;
  final String message;
  final String? bookingId;
  final String? serial;
  final String? scanned;
  final String? qrData;
  final String? scannedAt;
  final String? scannedByName;
  final String? scannedByUser;

  const CheckQrResponse({
    required this.alertType,
    required this.message,
    this.bookingId,
    this.serial,
    this.scanned,
    this.qrData,
    this.scannedAt,
    this.scannedByName,
    this.scannedByUser,
  });

  bool get isSuccess => alertType.toLowerCase() == 'success';
  bool get isScanned => scanned?.toLowerCase() == 'yes';
  bool get needsVerification => scanned?.toLowerCase() == 'no';

  factory CheckQrResponse.fromJson(Map<String, dynamic> json) {
    // Шинэ API response format (op: "scan")
    if (json['ok'] == true && json['data'] != null) {
      final data = json['data'] as Map<String, dynamic>;
      final scanned = data['scanned']?.toString() ?? 'no';

      return CheckQrResponse(
        alertType: scanned == 'yes' ? 'error' : 'info',
        message: scanned == 'yes' ? 'Already scanned' : 'Not scanned yet',
        serial: data['serial']?.toString(),
        scanned: scanned,
        qrData: data['qr_data']?.toString(),
        bookingId: data['qr_data']?.toString(),
        scannedAt: data['scanned_at']?.toString(),
        scannedByName: data['scanned_by_name']?.toString(),
        scannedByUser: data['scanned_by_user']?.toString(),
      );
    }

    // Fallback to old format
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
    if (serial != null) 'serial': serial,
    if (scanned != null) 'scanned': scanned,
    if (qrData != null) 'qr_data': qrData,
    if (scannedAt != null) 'scanned_at': scannedAt,
    if (scannedByName != null) 'scanned_by_name': scannedByName,
    if (scannedByUser != null) 'scanned_by_user': scannedByUser,
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

  /// Step 1: Check QR code scan status
  Future<CheckQrResponse> checkQrScan({
    required String token,
    required String qrData,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/');

    final requestBody = {'op': 'scan', 'qr_data': qrData, 'token': token};

    print('🔵 CHECK QR SCAN REQUEST:');
    print('   URL: $uri');
    print('   Method: POST');
    print('   Headers: {');
    print('     "Accept": "application/json",');
    print('     "Content-Type": "application/json"');
    print('   }');
    print('   Body: ${json.encode(requestBody)}');
    print(
      '   Token (first 20 chars): ${token.length > 20 ? token.substring(0, 20) : token}...',
    );

    final resp = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    print('🟢 CHECK QR SCAN RESPONSE:');
    print('   Status: ${resp.statusCode}');
    print('   Body: ${resp.body}');

    if (resp.statusCode != 200) {
      print('❌ QR scan check failed with status ${resp.statusCode}');
      throw Exception('QR scan check failed: ${resp.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(resp.body);

    if (data['ok'] != true) {
      print('❌ API returned ok=false: ${data['message']}');
      throw Exception(
        'QR scan check failed: ${data['message'] ?? 'Unknown error'}',
      );
    }

    return CheckQrResponse.fromJson(data);
  }

  /// Step 2: Verify/mark the ticket as scanned
  Future<CheckQrResponse> verifyQrScan({
    required String token,
    required String serial,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/');

    final requestBody = {'op': 'scan_verify', 'serial': serial, 'token': token};

    print('🔵 VERIFY QR SCAN REQUEST:');
    print('   URL: $uri');
    print('   Method: POST');
    print('   Headers: {');
    print('     "Accept": "application/json",');
    print('     "Content-Type": "application/json"');
    print('   }');
    print('   Body: ${json.encode(requestBody)}');
    print('   Serial: $serial');
    print(
      '   Token (first 20 chars): ${token.length > 20 ? token.substring(0, 20) : token}...',
    );

    final resp = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    print('🟢 VERIFY QR SCAN RESPONSE:');
    print('   Status: ${resp.statusCode}');
    print('   Body: ${resp.body}');

    if (resp.statusCode != 200) {
      print('❌ QR scan verification failed with status ${resp.statusCode}');
      throw Exception('QR scan verification failed: ${resp.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(resp.body);

    if (data['ok'] != true) {
      print('❌ API returned ok=false: ${data['message']}');
      throw Exception(
        'QR scan verification failed: ${data['message'] ?? 'Unknown error'}',
      );
    }

    print('✅ QR scan verified successfully!');
    // After successful verification, return success response
    return const CheckQrResponse(alertType: 'success', message: 'Verified');
  }

  /// Check a scanned QR code against the backend.
  ///
  /// New 2-step flow:
  /// 1. Check scan status with op: "scan"
  /// 2. If not scanned, verify with op: "scan_verify"
  Future<CheckQrResponse> checkQrCode({
    required String token,
    required UserRole role,
    required String bookingId,
  }) async {
    print('');
    print('═══════════════════════════════════════════');
    print('🎫 Starting QR Code Verification Flow');
    print('═══════════════════════════════════════════');
    print('   Booking ID: $bookingId');
    print(
      '   Token available: ${token.isNotEmpty ? "Yes (${token.length} chars)" : "No"}',
    );
    print('   User Role: ${role.name}');
    print('');

    try {
      // Step 1: Check scan status
      print('📍 STEP 1: Checking scan status...');
      final checkResponse = await checkQrScan(token: token, qrData: bookingId);

      print('');
      print('📊 Scan Status Result:');
      print('   Scanned: ${checkResponse.scanned}');
      print('   Serial: ${checkResponse.serial ?? "N/A"}');
      print('   Message: ${checkResponse.message}');

      // If already scanned, return error
      if (checkResponse.isScanned) {
        print('⚠️ Ticket already scanned!');
        print('   Scanned at: ${checkResponse.scannedAt ?? "N/A"}');
        print('   Scanned by: ${checkResponse.scannedByName ?? "N/A"}');
        print('═══════════════════════════════════════════');
        print('');
        return CheckQrResponse(
          alertType: 'error',
          message: 'Already scanned',
          bookingId: bookingId,
          serial: checkResponse.serial,
          scanned: 'yes',
          qrData: bookingId,
          scannedAt: checkResponse.scannedAt,
          scannedByName: checkResponse.scannedByName,
          scannedByUser: checkResponse.scannedByUser,
        );
      }

      // Step 2: If not scanned, verify it
      if (checkResponse.needsVerification && checkResponse.serial != null) {
        print('');
        print('📍 STEP 2: Marking ticket as scanned...');
        await verifyQrScan(token: token, serial: checkResponse.serial!);

        print('═══════════════════════════════════════════');
        print('');
        // Return success after verification
        return CheckQrResponse(
          alertType: 'success',
          message: 'Verified',
          bookingId: bookingId,
          serial: checkResponse.serial,
          scanned: 'yes',
          qrData: bookingId,
        );
      }

      // Fallback
      print('⚠️ Unexpected response - returning as is');
      print('═══════════════════════════════════════════');
      print('');
      return checkResponse;
    } catch (e) {
      print('');
      print('❌ ERROR in checkQrCode:');
      print('   $e');
      print('═══════════════════════════════════════════');
      print('');
      return CheckQrResponse(
        alertType: 'error',
        message: 'Verification failed: $e',
        bookingId: bookingId,
      );
    }
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
