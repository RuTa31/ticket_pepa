import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

class SalesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<SalesEvent> _events = [];
  bool _loading = false;
  String? _error;

  List<SalesEvent> get events => _events;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadEvents({required String token}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Use dashboard endpoint — no dedicated sales events list in new API
      final dashboard = await _api.getDashboard(token: token);
      _events = dashboard.events
          .map((e) => SalesEvent.fromDashboardEvent(e))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _loading = false;
    notifyListeners();
  }
}
