import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanItem {
  final String value;
  final DateTime time;
  final String? eventId;
  final String? eventTitle;
  final String? eventThumbnail;

  ScanItem({
    required this.value,
    required this.time,
    this.eventId,
    this.eventTitle,
    this.eventThumbnail,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'time': time.toIso8601String(),
    if (eventId != null) 'event_id': eventId,
    if (eventTitle != null) 'event_title': eventTitle,
    if (eventThumbnail != null) 'event_thumbnail': eventThumbnail,
  };

  static ScanItem fromJson(Map<String, dynamic> json) => ScanItem(
    value: json['value'] as String,
    time: DateTime.parse(json['time'] as String),
    eventId: json['event_id'] as String?,
    eventTitle: json['event_title'] as String?,
    eventThumbnail: json['event_thumbnail'] as String?,
  );
}

class ScanHistoryProvider extends ChangeNotifier {
  static const _prefsKey = 'scan_history_v2'; // Changed version to clear old data

  final List<ScanItem> _items = [];
  bool _loaded = false;

  List<ScanItem> get items => List.unmodifiable(_items.reversed);
  bool get isLoaded => _loaded;

  ScanHistoryProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    _items
      ..clear()
      ..addAll(
        raw.map(
          (s) => ScanItem.fromJson(jsonDecode(s) as Map<String, dynamic>),
        ),
      );
    _loaded = true;
    notifyListeners();
  }

  Future<void> addScan(
    String value, {
    String? eventId,
    String? eventTitle,
    String? eventThumbnail,
  }) async {
    final item = ScanItem(
      value: value,
      time: DateTime.now(),
      eventId: eventId,
      eventTitle: eventTitle,
      eventThumbnail: eventThumbnail,
    );
    _items.add(item);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> removeAt(int indexFromNewest) async {
    // items getter returns reversed. Convert index to original order index.
    final originalIndex = _items.length - 1 - indexFromNewest;
    if (originalIndex >= 0 && originalIndex < _items.length) {
      _items.removeAt(originalIndex);
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _items
        .map((e) => jsonEncode(e.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_prefsKey, raw);
  }
}
