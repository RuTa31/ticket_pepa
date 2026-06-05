import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import '../history/scan_history_provider.dart';
import '../settings/app_settings_provider.dart';
import '../auth/providers/auth_provider.dart';

import 'scanner_provider.dart';

class QrScannerPage extends StatefulWidget {
  final bool isActive;
  final bool showBack;
  const QrScannerPage({super.key, this.isActive = true, this.showBack = true});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  StreamSubscription<Barcode>? _scanSubscription;
  bool _isProcessingCode = false;

  @override
  void didUpdateWidget(QrScannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle tab change - only if controller exists AND QRView is active
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        // Tab became active - controller will be created by QRView
        // ensureRunning will be called in _onQRViewCreated
      } else {
        // Tab became inactive - clear controller reference
        final provider = context.read<ScannerProvider>();
        _scanSubscription?.cancel();
        _scanSubscription = null;
        provider.setController(null);
        provider.stopScanner();
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    final controller = context.read<ScannerProvider>().controller;
    if (controller != null && Platform.isAndroid) {
      try {
        controller.pauseCamera();
        controller.resumeCamera();
      } catch (_) {
        // Ignore if camera not ready
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    final scannerProvider = context.read<ScannerProvider>();
    scannerProvider.setController(controller);

    // Cancel previous subscription if any
    _scanSubscription?.cancel();

    // Create new subscription
    _scanSubscription = controller.scannedDataStream.listen((scanData) {
      if (scannerProvider.canDetect &&
          scannerProvider.scanningReady &&
          !scannerProvider.processing) {
        _onDetect(scanData.code);
      }
    });

    // Now that controller is set, ensure camera is running
    if (widget.isActive) {
      scannerProvider.ensureRunning(true);
    }
  }

  void _onDetect(String? code) async {
    // FIRST check - block if already processing a code
    if (_isProcessingCode) return;

    final scannerProvider = context.read<ScannerProvider>();

    // Triple safety check: canDetect, processing, and scanningReady
    if (!scannerProvider.canDetect ||
        scannerProvider.processing ||
        !scannerProvider.scanningReady) {
      return;
    }

    if (code == null || code.isEmpty) return;

    // Check if this code was already scanned recently (prevent duplicates)
    if (!scannerProvider.shouldProcessCode(code)) {
      return;
    }

    // Set processing flag IMMEDIATELY
    _isProcessingCode = true;

    // Pause the stream subscription to stop receiving events
    _scanSubscription?.pause();

    // Lock scanning IMMEDIATELY - this sets all flags to prevent re-detection
    scannerProvider.lockScanning();

    // Stop camera controller
    scannerProvider.stopScanner();

    // Optional vibration feedback
    try {
      if (context.read<AppSettingsProvider>().vibrateOnScan) {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final payload = await scannerProvider.verifyCode(code: code, auth: auth);

    // Save to history with event information if available
    if (mounted) {
      String? eventId;
      String? eventTitle;
      String? eventThumbnail;

      // Use ticket info from scan payload if available
      final ticketEventId = payload?['ticket_event_id'] as int?;
      final ticketEventName = payload?['ticket_event'] as String?;
      if (ticketEventId != null) {
        eventId = ticketEventId.toString();
        eventTitle = ticketEventName;
        // Dashboard events have no thumbnail in new API
      }

      context.read<ScanHistoryProvider>().addScan(
        code,
        eventId: eventId,
        eventTitle: eventTitle,
        eventThumbnail: eventThumbnail,
      );
    }

    if (!mounted) return;
    await Navigator.of(
      context,
    ).pushNamed('/result', arguments: payload ?? code);
    if (!context.mounted) return;

    // Clear processing flag and resume stream
    _isProcessingCode = false;
    _scanSubscription?.resume();

    // Restart scanner with 3 second delay before next scan
    scannerProvider.ensureRunning(widget.isActive);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Consumer<ScannerProvider>(
      builder: (context, scanner, _) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 1,
            backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
            // title: const NetworkAppLogo(height: 28),
            title: const Text(
              'Pepa Ticket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.cameraswitch,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => scanner.switchCamera(),
                tooltip: l10n.switchCamera,
              ),
              IconButton(
                icon: Icon(
                  Icons.flash_on,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => scanner.toggleTorch(),
                tooltip: l10n.toggleTorch,
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Only render QRView when scanner tab is active
              if (widget.isActive)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: Colors.white,
                        borderRadius: 16,
                        borderLength: 28,
                        borderWidth: 4,
                        cutOutSize: constraints.maxWidth * 0.75,
                        overlayColor: Colors.black45,
                      ),
                    );
                  },
                ),
              // Verifying overlay using provider state
              if (scanner.verifying)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Verifying...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}
