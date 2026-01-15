import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../services/api_client.dart';
import '../auth/providers/auth_provider.dart';

class ScannerProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _processing = false;
  bool _verifyingUi = false;
  Timer? _loaderTimer;
  QRViewController? _controller;
  bool _scanningReady = false;
  Timer? _delayTimer;
  bool _canDetect = true; // Flag to completely disable detection
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
    // Don't start if processing or no controller
    if (_processing) return;

    if (isActive && !_processing) {
      _canDetect = true; // Re-enable detection
      // DON'T reset scan history - we want to prevent rescanning same code
      if (_controller != null) {
        try {
          _controller?.resumeCamera();
        } catch (e) {
          // Silently ignore - camera view not ready
          if (kDebugMode) {
            print('Camera resume ignored: $e');
          }
        }
      }
      // Wait 1.5 seconds before allowing scans
      _scanningReady = false;
      _delayTimer?.cancel();
      _delayTimer = Timer(const Duration(milliseconds: 1500), () {
        _scanningReady = true;
        // Don't notify listeners - no need to rebuild UI
      });
    } else {
      if (_controller != null) {
        try {
          _controller?.pauseCamera();
        } catch (e) {
          // Silently ignore - camera view not ready
          if (kDebugMode) {
            print('Camera pause ignored: $e');
          }
        }
      }
      _scanningReady = false;
      _canDetect = false;
      _delayTimer?.cancel();
    }
  }

  void stopScanner() {
    _canDetect = false; // Disable detection FIRST
    _scanningReady = false;
    _delayTimer?.cancel();
    if (_controller != null) {
      try {
        _controller?.pauseCamera();
      } catch (e) {
        // Silently ignore - camera view not ready
        if (kDebugMode) {
          print('Camera pause ignored: $e');
        }
      }
    }
  }

  // Immediately lock scanning to prevent any detection
  void lockScanning() {
    _canDetect = false;
    _scanningReady = false;
    // Don't set _processing here - verifyCode will do it
  }

  // Check if this code should be processed (prevent duplicate scans)
  bool shouldProcessCode(String code) {
    final now = DateTime.now();

    // If same code scanned within 3 seconds, ignore
    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 3)) {
      return false;
    }

    _lastScannedCode = code;
    _lastScanTime = now;
    return true;
  }

  // Reset scan history when restarting
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
    // Don't dispose controller - it self-disposes when QRView unmounts
    super.dispose();
  }

  /// Verifies the scanned code with the backend and returns a payload
  /// that the result screen can display.
  Future<Map<String, dynamic>?> verifyCode({
    required String code,
    required AuthProvider auth,
  }) async {
    if (_processing) return null;
    _processing = true;
    notifyListeners();

    // Show loader if request takes longer than threshold
    _loaderTimer?.cancel();
    _loaderTimer = Timer(const Duration(milliseconds: 400), () {
      _verifyingUi = true;
      notifyListeners();
    });

    Map<String, dynamic>? payload;
    try {
      final token = auth.token;
      final profile = auth.profile;
      if (auth.isLoggedIn && token != null && profile != null) {
        final res = await _api.checkQrCode(
          token: token,
          role: profile.role,
          bookingId: code,
        );
        payload = {
          'value': code,
          'apiMessage': res.message,
          'alertType': res.alertType,
          if (res.bookingId != null) 'booking_id': res.bookingId,
          if (res.scannedAt != null) 'scanned_at': res.scannedAt,
          if (res.scannedByName != null) 'scanned_by_name': res.scannedByName,
          if (res.scannedByUser != null) 'scanned_by_user': res.scannedByUser,
        };
      } else {
        payload = {'value': code};
      }
    } catch (_) {
      // Fallback to basic payload on network or parsing errors
      payload = {'value': code};
    } finally {
      _loaderTimer?.cancel();
      if (_verifyingUi) {
        _verifyingUi = false;
      }
      _processing = false;
      notifyListeners();
    }

    return payload;
  }
}
