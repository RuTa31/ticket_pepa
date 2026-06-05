import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../home/models/dashboard_models.dart';

void _log(String method, Uri uri, {String? reqBody, int? status, String? resBody}) {
  if (!kDebugMode) return;
  final sep = '─' * 60;
  debugPrint('\n$sep');
  debugPrint('▶ $method ${uri.path}');
  if (reqBody != null) {
    try {
      final pretty = const JsonEncoder.withIndent('  ').convert(json.decode(reqBody));
      debugPrint('  BODY: $pretty');
    } catch (_) {
      debugPrint('  BODY: $reqBody');
    }
  }
  if (status != null) {
    debugPrint('◀ $status');
    if (resBody != null) {
      try {
        final pretty = const JsonEncoder.withIndent('  ').convert(json.decode(resBody));
        debugPrint(pretty);
      } catch (_) {
        debugPrint(resBody);
      }
    }
  }
  debugPrint(sep);
}

const String apiBaseUrl = 'https://pick.mn';

class UserProfile {
  final int id;
  final String username;
  final String? name;

  UserProfile({required this.id, required this.username, this.name});

  String get displayName =>
      (name != null && name!.isNotEmpty) ? name! : username;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}

class LoginSuccess {
  final String token;
  final UserProfile profile;
  LoginSuccess(this.token, this.profile);
}

class SalesPlan {
  final int id;
  final String name;
  final double price;
  final String currency;

  const SalesPlan({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'MNT',
  });

  factory SalesPlan.fromEventDetailPlan(EventDetailPlan plan) {
    return SalesPlan(
      id: plan.id,
      name: plan.name,
      price: plan.price,
      currency: plan.currency,
    );
  }

  factory SalesPlan.fromJson(Map<String, dynamic> json) {
    return SalesPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'MNT',
    );
  }
}

class SalesEvent {
  final int id;
  final String name;
  final String? picture;
  final List<SalesPlan> plans;

  const SalesEvent({
    required this.id,
    required this.name,
    this.picture,
    required this.plans,
  });

  String? get logoUrl => picture;

  factory SalesEvent.fromDashboardEvent(DashboardEvent event) {
    return SalesEvent(
      id: event.id,
      name: event.name,
      picture: null,
      plans: [],
    );
  }
}

class InvoiceResponse {
  final String payId;
  final String orderId;
  final int amount;
  final String qrImage;
  final String? paymentUrl;

  const InvoiceResponse({
    required this.payId,
    required this.orderId,
    required this.amount,
    required this.qrImage,
    this.paymentUrl,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>? ?? {};
    final payment = json['payment'] as Map<String, dynamic>? ?? {};
    final qpay = payment['qpay'] as Map<String, dynamic>? ?? {};
    final orderGateways =
        (order['payment_gateways'] as Map<String, dynamic>?) ?? {};
    final orderQpay =
        (orderGateways['qpay'] as Map<String, dynamic>?) ?? {};

    final qrImage =
        qpay['qr_image']?.toString() ??
        orderQpay['qr_image']?.toString() ??
        '';

    return InvoiceResponse(
      payId: order['pay_id']?.toString() ?? '',
      orderId: order['order_id']?.toString() ?? '',
      amount: (order['amount'] as num?)?.toInt() ?? 0,
      qrImage: qrImage,
      paymentUrl: json['payment_url']?.toString(),
    );
  }
}

class TicketInfo {
  final String? code;
  final String? serial;

  const TicketInfo({this.code, this.serial});

  factory TicketInfo.fromJson(Map<String, dynamic> json) {
    return TicketInfo(
      code: json['code']?.toString(),
      serial: json['serial']?.toString(),
    );
  }
}

class PaymentStatusResponse {
  final String status;
  final List<TicketInfo> ticketInfo;

  const PaymentStatusResponse({
    required this.status,
    this.ticketInfo = const [],
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isFailed => status != 'pending' && status != 'paid';

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>? ?? {};
    final tickets = (json['tickets'] as List?)
            ?.map((t) => TicketInfo.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [];
    return PaymentStatusResponse(
      status: order['status']?.toString() ?? 'pending',
      ticketInfo: tickets,
    );
  }
}

class ApiClient {
  final http.Client _client;
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _authHeaders(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// POST /api/v1/scanner/auth/login
  Future<LoginSuccess> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/scanner/auth/login');
    final reqBody = json.encode({'username': username, 'password': password});
    _log('POST', uri, reqBody: reqBody);
    final resp = await _client.post(
      uri,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: reqBody,
    );
    _log('POST', uri, status: resp.statusCode, resBody: resp.body);

    if (resp.statusCode != 200) {
      throw Exception('Login failed: ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    if (data['status'] != 'success') {
      throw Exception(data['message']?.toString() ?? 'Invalid credentials');
    }

    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) throw Exception('No token received');

    final staffJson = data['staff'] as Map<String, dynamic>? ?? {};
    final profile = UserProfile(
      id: (staffJson['id'] as num?)?.toInt() ?? 0,
      username: staffJson['username']?.toString() ?? username,
      name: staffJson['name']?.toString(),
    );

    return LoginSuccess(token, profile);
  }

  /// GET /api/v1/scanner/me — validates token and returns true if active
  Future<bool> checkToken(String token) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/scanner/me');
    _log('GET', uri);
    try {
      final resp = await _client.get(uri, headers: _authHeaders(token));
      _log('GET', uri, status: resp.statusCode, resBody: resp.body);
      return resp.statusCode == 200;
    } catch (_) {
      rethrow;
    }
  }

  /// GET /api/v1/scanner/me — returns full staff profile
  Future<UserProfile> getMe(String token) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/scanner/me');
    _log('GET', uri);
    final resp = await _client.get(uri, headers: _authHeaders(token));
    _log('GET', uri, status: resp.statusCode, resBody: resp.body);

    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch profile: ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final staffJson = data['staff'] as Map<String, dynamic>? ?? {};
    return UserProfile.fromJson(staffJson);
  }

  /// GET /api/v1/scanner/dashboard
  Future<DashboardData> getDashboard({required String token}) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/scanner/dashboard');
    _log('GET', uri);
    final resp = await _client.get(uri, headers: _authHeaders(token));
    _log('GET', uri, status: resp.statusCode, resBody: resp.body);

    if (resp.statusCode != 200) {
      throw Exception('Failed to load dashboard: ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    if (data['status'] != 'success') {
      throw Exception(data['message']?.toString() ?? 'Dashboard load failed');
    }

    return DashboardData.fromJson(data);
  }

  /// GET /api/v1/scanner/events/{eventId}
  Future<EventDetail> getEventDetail({
    required String token,
    required int eventId,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/scanner/events/$eventId');
    _log('GET', uri);
    final resp = await _client.get(uri, headers: _authHeaders(token));
    _log('GET', uri, status: resp.statusCode, resBody: resp.body);

    if (resp.statusCode != 200) {
      throw Exception('Failed to load event detail: ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    if (data['status'] != 'success') {
      throw Exception(data['message']?.toString() ?? 'Event detail load failed');
    }

    final eventJson = data['event'] as Map<String, dynamic>? ?? {};
    return EventDetail.fromJson(eventJson);
  }

  /// POST /api/v1/scanner/tickets/scan
  Future<ScanTicketResult> scanTicket({
    required String token,
    required String code,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/scanner/tickets/scan');
    final reqBody = json.encode({'code': code, 'device_id': deviceId});
    _log('POST', uri, reqBody: reqBody);
    final resp = await _client.post(
      uri,
      headers: _authHeaders(token),
      body: reqBody,
    );
    _log('POST', uri, status: resp.statusCode, resBody: resp.body);

    if (resp.statusCode != 200) {
      throw Exception('Scan failed: ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    return ScanTicketResult.fromJson(data);
  }

  /// POST /api/v1/scanner/orders
  Future<InvoiceResponse> createOrder({
    required String token,
    required int eventId,
    required int planId,
    required int qty,
    required String email,
    required String phone,
    required String deviceId,
    required String redirectUri,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/scanner/orders');
    final reqBody = json.encode({
      'event_id': eventId,
      'plan_id': planId,
      'qty': qty,
      'email': email,
      'phone': phone,
      'device_id': deviceId,
      'redirect_uri': redirectUri,
    });
    _log('POST', uri, reqBody: reqBody);
    final resp = await _client.post(
      uri,
      headers: _authHeaders(token),
      body: reqBody,
    );
    _log('POST', uri, status: resp.statusCode, resBody: resp.body);

    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception('Failed to create order: ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    if (data['status'] != 'success') {
      throw Exception(data['message']?.toString() ?? 'Failed to create order');
    }

    return InvoiceResponse.fromJson(data);
  }

  /// GET /api/v1/scanner/orders/{payId}
  Future<PaymentStatusResponse> checkOrder({
    required String token,
    required String payId,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/scanner/orders/$payId');
    _log('GET', uri);
    final resp = await _client.get(uri, headers: _authHeaders(token));
    _log('GET', uri, status: resp.statusCode, resBody: resp.body);

    if (resp.statusCode != 200) {
      throw Exception('Failed to check order: ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    return PaymentStatusResponse.fromJson(data);
  }
}
