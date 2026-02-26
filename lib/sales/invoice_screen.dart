import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import '../common/app_colors.dart';
import '../services/api_client.dart';

enum _InvoiceState { form, loading, qrPayment, paid, failed }

class InvoiceScreen extends StatefulWidget {
  final int eventId;
  final String eventName;
  final int planId;
  final String planName;
  final double price;

  const InvoiceScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.planId,
    required this.planName,
    required this.price,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final ApiClient _api = ApiClient();

  int _qty = 1;
  _InvoiceState _state = _InvoiceState.form;
  String? _error;

  InvoiceResponse? _invoice;
  PaymentStatusResponse? _paymentStatus;
  Timer? _pollTimer;
  bool _manualChecking = false;

  double get _totalAmount => widget.price * _qty;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createInvoice() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    setState(() {
      _state = _InvoiceState.loading;
      _error = null;
    });

    try {
      final invoice = await _api.createInvoice(
        token: auth.token!,
        eventId: widget.eventId,
        eventPlanId: widget.planId,
        qty: _qty,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _state = _InvoiceState.qrPayment;
      });

      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _state = _InvoiceState.form;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkPayment();
    });
  }

  Future<void> _checkPayment({bool manual = false}) async {
    if (_invoice == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    if (manual) {
      setState(() => _manualChecking = true);
    }

    try {
      final status = await _api.checkInvoice(
        token: auth.token!,
        orderId: _invoice!.orderId,
      );

      if (!mounted) return;

      if (status.isPaid) {
        _pollTimer?.cancel();
        setState(() {
          _paymentStatus = status;
          _state = _InvoiceState.paid;
          _manualChecking = false;
        });
      } else if (status.isFailed) {
        _pollTimer?.cancel();
        setState(() {
          _paymentStatus = status;
          _state = _InvoiceState.failed;
          _manualChecking = false;
        });
      } else {
        if (manual && mounted) {
          setState(() => _manualChecking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Төлбөр хүлээгдэж байна...'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _manualChecking = false);
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа: ${e.toString().replaceFirst('Exception: ', '')}'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _retryNewInvoice() {
    _pollTimer?.cancel();
    setState(() {
      _invoice = null;
      _paymentStatus = null;
      _state = _InvoiceState.form;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        title: Text(
          l10n.invoice,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: switch (_state) {
        _InvoiceState.form => _buildForm(isDark),
        _InvoiceState.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        _InvoiceState.qrPayment => _buildQrPayment(isDark),
        _InvoiceState.paid => _buildPaidResult(isDark),
        _InvoiceState.failed => _buildFailed(isDark),
      },
    );
  }

  // ─── FORM STATE ───────────────────────────────────────────

  Widget _buildForm(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Event detail card
          Card(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eventName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(l10n.plan, widget.planName, isDark),
                  _infoRow(
                    l10n.unitPrice,
                    '${widget.price.toStringAsFixed(0)}₮',
                    isDark,
                  ),
                  const Divider(height: 24),
                  // Qty stepper
                  Row(
                    children: [
                      Text(
                        l10n.ticketCount,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      _buildStepper(isDark),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Text(
                        l10n.totalAmount,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_totalAmount.toStringAsFixed(0)}₮',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact info card
          Card(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.contactInfo,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.phoneNumber,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _createInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: Text(
                l10n.createInvoice,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(Icons.remove, () {
            if (_qty > 1) setState(() => _qty--);
          }, isDark),
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            alignment: Alignment.center,
            child: Text(
              '$_qty',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _stepperButton(Icons.add, () {
            setState(() => _qty++);
          }, isDark),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 22, color: AppColors.primaryColor),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─── QR PAYMENT STATE ─────────────────────────────────────

  Widget _buildQrPayment(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final invoice = _invoice!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // QR Card
          Card(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    l10n.totalPayAmount,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.amount}₮',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // QR image from base64
                  if (invoice.qrImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(invoice.qrImage),
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Polling indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange.shade600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.waitingForPayment,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Manual check button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _manualChecking ? null : () => _checkPayment(manual: true),
              icon: _manualChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_manualChecking ? l10n.checking : l10n.checkPayment),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PAID STATE ───────────────────────────────────────────

  Widget _buildPaidResult(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final tickets = _paymentStatus?.ticketInfo ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Success card
          Card(
            color: Colors.green.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.green.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 56,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.paymentSuccess,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_invoice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.orderNumberLabel(_invoice!.orderId),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ticket list
          if (tickets.isNotEmpty)
            ...tickets.map((ticket) => _buildTicketCard(ticket, isDark)),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil(
                (route) => route.isFirst || route.settings.name == '/main',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.back,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketInfo ticket, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: isDark ? Colors.grey.shade900 : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ticket.serial != null)
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.serialLabel(ticket.serial!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (ticket.qrImg != null) ...[
              const SizedBox(height: 10),
              Center(
                child: Image.network(
                  ticket.qrImg!,
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 160,
                    height: 160,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ],
            if (ticket.qrCode != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.qrCode!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: ticket.qrCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.copied),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy,
                        size: 18,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── FAILED STATE ─────────────────────────────────────────

  Widget _buildFailed(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: Colors.red.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel, size: 56, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  l10n.paymentFailed,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _retryNewInvoice,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retryPayment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
