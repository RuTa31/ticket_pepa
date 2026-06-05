import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../common/app_colors.dart';
import '../home/models/dashboard_models.dart';

class QrResultScreen extends StatefulWidget {
  final String value;
  final String? status;       // "accepted" | "duplicate" | "invalid" | "wrong_event"
  final String? message;
  final bool accepted;
  final String? ticketCode;
  final String? ticketEvent;
  final String? ticketPlan;
  final int? scanCount;
  final String? firstScannedBy;
  final int? firstScannedAt;  // Unix timestamp
  final ScanCustomForm? customForm;

  const QrResultScreen({
    super.key,
    required this.value,
    this.status,
    this.message,
    this.accepted = false,
    this.ticketCode,
    this.ticketEvent,
    this.ticketPlan,
    this.scanCount,
    this.firstScannedBy,
    this.firstScannedAt,
    this.customForm,
  });

  @override
  State<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends State<QrResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _checkAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;

  bool get isAccepted => widget.status == 'accepted';
  bool get isDuplicate => widget.status == 'duplicate';
  bool get isWrongEvent => widget.status == 'wrong_event';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkAnimationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _checkAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _checkAnimationController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    if (isAccepted) return Colors.green;
    if (isDuplicate) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String get _titleText {
    if (isAccepted) return 'БИЛЕТ БАТАЛГААЖЛАА';
    if (isDuplicate) return 'АЛЬ ХЭДИЙН УНШИГДСАН';
    if (isWrongEvent) return 'БУРУУ АРГА ХЭМЖЭЭ';
    return 'ХҮЧИНГҮЙ БИЛЕТ';
  }

  String _fmtTimestamp(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final y = dt.year;
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y.$mo.$d $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final accentColor = _accentColor;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        elevation: 1,
        title: Text(
          l10n.result,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: isDark ? Colors.white : Colors.black),
            tooltip: l10n.history,
            onPressed: () => Navigator.of(context).pushNamed('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Animated icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: isAccepted
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _checkAnimation,
                                builder: (context, child) => CustomPaint(
                                  size: const Size(140, 140),
                                  painter: _CircularProgressPainter(
                                    progress: _checkAnimation.value,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      accentColor.withValues(alpha: 0.2),
                                      accentColor.withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              ScaleTransition(
                                scale: _checkAnimation,
                                child: Icon(Icons.verified_rounded, size: 80, color: accentColor),
                              ),
                            ],
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withValues(alpha: 0.2),
                                  accentColor.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              isDuplicate
                                  ? Icons.warning_amber_rounded
                                  : Icons.cancel_rounded,
                              size: 90,
                              color: accentColor,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  _titleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.message != null && widget.message!.isNotEmpty)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    widget.message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Ticket info card (for accepted + duplicate)
              if ((isAccepted || isDuplicate) &&
                  (widget.ticketEvent != null || widget.ticketPlan != null))
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _infoCard(
                    accentColor: accentColor,
                    isDark: isDark,
                    children: [
                      if (widget.ticketEvent != null)
                        _infoRow(Icons.event, 'Арга хэмжээ', widget.ticketEvent!, isDark),
                      if (widget.ticketPlan != null)
                        _infoRow(Icons.label_outline, 'Тасалбарын төрөл', widget.ticketPlan!, isDark),
                      if (widget.ticketCode != null)
                        _infoRow(Icons.confirmation_number_outlined, 'Код', widget.ticketCode!, isDark),
                    ],
                  ),
                ),
              // Duplicate info card
              if (isDuplicate &&
                  (widget.scanCount != null || widget.firstScannedBy != null))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _infoCard(
                      accentColor: Colors.red.shade700,
                      isDark: isDark,
                      children: [
                        if (widget.scanCount != null)
                          _infoRow(
                            Icons.repeat,
                            'Нийт уншсан тоо',
                            '${widget.scanCount} удаа',
                            isDark,
                          ),
                        if (widget.firstScannedBy != null)
                          _infoRow(
                            Icons.person_outline,
                            'Анх уншсан',
                            widget.firstScannedBy!,
                            isDark,
                          ),
                        if (widget.firstScannedAt != null)
                          _infoRow(
                            Icons.access_time,
                            'Анх уншсан цаг',
                            _fmtTimestamp(widget.firstScannedAt!),
                            isDark,
                          ),
                      ],
                    ),
                  ),
                ),
              // Custom form card
              if (widget.customForm != null && widget.customForm!.fields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _infoCard(
                      accentColor: Colors.blue.shade600,
                      isDark: isDark,
                      headerLabel: widget.customForm!.name,
                      children: widget.customForm!.fields
                          .map((f) => _infoRow(Icons.info_outline, f.label, f.value, isDark))
                          .toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // QR code value card
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, color: AppColors.primaryColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            l10n.qrCodeData,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SelectableText(
                          widget.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                  label: Text(
                    l10n.scanAgain,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _fadeAnimation,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: isDark ? Colors.white30 : Colors.grey.shade300,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.home_rounded, size: 24),
                  label: Text(
                    l10n.backToHome,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/main',
                      (route) => route.settings.name == '/',
                      arguments: {'initialTab': 0},
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required Color accentColor,
    required bool isDark,
    required List<Widget> children,
    String? headerLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerLabel != null) ...[
            Text(
              headerLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 2, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final sweepAngle = 2 * 3.141592653589793 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        -3.141592653589793 / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      if (progress < 1.0) {
        final dotAngle = -3.141592653589793 / 2 + sweepAngle;
        final dotX = center.dx + (radius - 2) * cos(dotAngle);
        final dotY = center.dy + (radius - 2) * sin(dotAngle);
        canvas.drawCircle(
          Offset(dotX, dotY),
          4,
          Paint()..color = color..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
