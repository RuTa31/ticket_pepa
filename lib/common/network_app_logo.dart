import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/basic_service.dart';

class NetworkAppLogo extends StatefulWidget {
  final double? width;
  final double height;
  final String type;

  const NetworkAppLogo({
    super.key,
    this.width,
    required this.height,
    this.type = 'logo',
  });

  @override
  State<NetworkAppLogo> createState() => _NetworkAppLogoState();
}

class _NetworkAppLogoState extends State<NetworkAppLogo> {
  Uint8List? _bytes;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _loadOnce();
    _listener = () => _loadOnce();
    try {
      BasicService.brandingVersion.addListener(_listener);
    } catch (_) {}
  }

  Future<void> _loadOnce() async {
    try {
      final b = await BasicService.getCachedBrandingBytes(widget.type);
      if (!mounted) return;
      setState(() => _bytes = (b != null && b.isNotEmpty) ? b : null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _bytes = null);
    }
  }

  Widget _fallbackWidget() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null && _bytes!.isNotEmpty) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
      );
    }

    return _fallbackWidget();
  }

  @override
  void dispose() {
    try {
      BasicService.brandingVersion.removeListener(_listener);
    } catch (_) {}
    super.dispose();
  }
}
