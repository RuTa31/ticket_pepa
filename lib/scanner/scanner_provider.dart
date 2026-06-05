import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../services/api_client.dart';
import '../services/device_id.dart';
import '../auth/providers/auth_provider.dart';
import '../home/models/dashboard_models.dart';

class ScannerProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _processing = false;
  bool _verifyingUi = false;
  Timer? _loaderTimer;
  QRViewController? _controller;
  bool _scanningReady = false;
  Timer? _delayTimer;
  bool _canDetect = true;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  bool get processing => _processing;
  bool get verifying => _verifyingUi;
  bool get scanningReady => _scanningReady;
  bool get canDetect => _canDetect;
  QRViewController? get controller => _controller;

  void setController(QRViewController? controller) {
    _controller = controller;
  }

  void ensureRunning(bool isActive) {
    if (_processing) return;

    if (isActive && !_processing) {
      _canDetect = true;
      if (_controller != null) {
        try {
          _controller?.resumeCamera();
        } catch (e) {
          if (kDebugMode) print('Camera resume ignored: $e');
        }
      }
      _scanningReady = false;
      _delayTimer?.cancel();
      _delayTimer = Timer(const Duration(milliseconds: 1500), () {
        _scanningReady = true;
      });
    } else {
      if (_controller != null) {
        try {
          _controller?.pauseCamera();
        } catch (e) {
          if (kDebugMode) print('Camera pause ignored: $e');
        }
      }
      _scanningReady = false;
      _canDetect = false;
      _delayTimer?.cancel();
    }
  }

  void stopScanner() {
    _canDetect = false;
    _scanningReady = false;
    _delayTimer?.cancel();
    if (_controller != null) {
      try {
        _controller?.pauseCamera();
      } catch (e) {
        if (kDebugMode) print('Camera pause ignored: $e');
      }
    }
  }

  void lockScanning() {
    _canDetect = false;
    _scanningReady = false;
  }

  bool shouldProcessCode(String code) {
    final now = DateTime.now();
    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 3)) {
      return false;
    }
    _lastScannedCode = code;
    _lastScanTime = now;
    return true;
  }

  void resetScanHistory() {
    _lastScannedCode = null;
    _lastScanTime = null;
  }

  void switchCamera() {
    _controller?.flipCamera();
  }

  void toggleTorch() {
    _controller?.toggleFlash();
  }

  @override
  void dispose() {
    _loaderTimer?.cancel();
    _delayTimer?.cancel();
    super.dispose();
  }

  /// Verifies the scanned code via POST /api/v1/scanner/tickets/scan
  /// Returns a payload map for the result screen.
  Future<Map<String, dynamic>?> verifyCode({
    required String code,
    required AuthProvider auth,
  }) async {
    if (_processing) return null;
    _processing = true;
    notifyListeners();

    _loaderTimer?.cancel();
    _loaderTimer = Timer(const Duration(milliseconds: 400), () {
      _verifyingUi = true;
      notifyListeners();
    });

    Map<String, dynamic>? payload;
    try {
      final token = auth.token;
      if (auth.isLoggedIn && token != null) {
        final deviceId = await DeviceId.getId();
        final ScanTicketResult res = await _api.scanTicket(
          token: token,
          code: code,
          deviceId: deviceId,
        );
        payload = {
          'value': code,
          'status': res.status,
          'message': res.message,
          'accepted': res.accepted,
          if (res.ticket != null) 'ticket_code': res.ticket!.code,
          if (res.ticket != null) 'ticket_event': res.ticket!.event,
          if (res.ticket != null) 'ticket_event_id': res.ticket!.eventId,
          if (res.ticket != null) 'ticket_plan': res.ticket!.plan,
          if (res.scan != null) 'scan_count': res.scan!.scanCount,
          if (res.scan?.firstStaff != null)
            'first_scanned_by': res.scan!.firstStaff!.name,
          if (res.scan?.firstScannedAt != null)
            'first_scanned_at': res.scan!.firstScannedAt,
          if (res.customForm != null) 'custom_form': res.customForm,
        };
      } else {
        payload = {'value': code, 'status': 'invalid', 'message': '', 'accepted': false};
      }
    } catch (_) {
      payload = {'value': code, 'status': 'invalid', 'message': '', 'accepted': false};
    } finally {
      _loaderTimer?.cancel();
      if (_verifyingUi) _verifyingUi = false;
      _processing = false;
      notifyListeners();
    }

    return payload;
  }
}
